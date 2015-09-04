module RackSegment
  class Middleware
    HTTP_HEADER_PREFIX = 'HTTP_EXPERIMENT_'
    RACK_SEGMENT_COOKIE = 'rack-segment'

    DEFAULT_OPTS = {
      :identifier => :rack_session
    }.freeze

    NoCookieError = Class.new(StandardError) do
      def initialize(cookie_name)
        super "No cookie named: #{cookie_name}"
      end
    end

    attr_reader :identifier, :cookie_name

    def initialize(app, opts = nil)
      @app = app
      @log = Logger.new(STDOUT)

      if opts.is_a?(Hash) && opts.count > 0
        @identifier, @cookie_name = *opts.first
      elsif opts.is_a?(String)
        @identifier = opts
      elsif opts.respond_to?(:call)
        @identifier = opts
      else
        @identifier = DEFAULT_OPTS[:identifier]
      end
    end

    def call(env)
      req = Rack::Request.new(env)
      
      identifier = retrieve_id(req)
      e_override, b_override = retrieve_overrides(req)

      experiment_headers = {}

      experiments.each do |e|
        unless bucket = override_values(e, e_override, b_override)
          bucket = retrieve_bucket(identifier, e)
        end
        experiment_headers[HTTP_HEADER_PREFIX + e.name.upcase] = bucket
      end

      experiment_headers.each { |header,bucket| env[header] = bucket }

      status, headers, body = @app.call(env)
      res = Rack::Response.new body, status, headers

      debug_info(env, headers) if debug_mode?

      store_over_in_cookie!(req, res)

      res.finish
    end

    private
    def store_over_in_cookie!(req, res)
      params = Rack::Utils.parse_nested_query(req.query_string)
      if params['segment']
        res.set_cookie(RACK_SEGMENT_COOKIE, :value => params['segment'], :path => "/")
      end
    end

    def override_values(experiment, e_override, b_override)
      if (e_override || '').downcase == experiment.name && b_override
        b_override
      elsif e_override.nil? && b_override
        b_override
      else
        nil
      end
    end

    def retrieve_overrides(req)
      params = Rack::Utils.parse_nested_query(req.query_string)
      experiment, bucket = (params['segment'] || '').split('|')

      unless experiment || bucket
        experiment, bucket = (req.cookies[RACK_SEGMENT_COOKIE] || '').split('|')
      end

      unless bucket
        bucket = experiment
        experiment = nil
      end
      [experiment, bucket]
    end

    def retrieve_bucket(identifier, experiment)
      unique = create_unique(identifier, experiment.name)

      begin
        if in_experiment?(unique, experiment.traffic)
          number_to_bucket(unique % experiment.bucket_count)
        else
          'excluded'
        end
      rescue NoCookieError => e
        @log.info "No Cookie found called #{cookie_name}"
        raise e unless debug_mode?
      rescue StandardError => e
        @log.info "Error when extracting identifier"
        raise e unless debug_mode?
      end
    end

    def create_unique(experiment_name, identifier)
      Digest::SHA1.hexdigest(experiment_name).to_i(0x10) + Digest::SHA1.hexdigest(identifier).to_i(0x10)
    end

    def in_experiment?(unique, traffic_percentage)
       ((unique % 100) / 100) <= traffic_percentage
    end

    def debug_mode?
      (ENV['RACK_ENV'] || ENV['RAILS_ENV']) != 'production'
    end

    def debug_info(env, headers)
      str_length = HTTP_HEADER_PREFIX.length
      experiment_headers = env.keys.select { |s| s.start_with?(HTTP_HEADER_PREFIX) }
      experiment_headers.each { |header| headers[header[str_length..-1]] = env[header] }
    end

    def experiments
      Experiment.list
    end

    def retrieve_id(req)
      case
        when identifier.respond_to?(:call)           then identifier.call(req.env)
        when identifier == :rack_session             then rack_session(req)
        when identifier == :cookie                   then cookie(req)
        else raise "Unsupported identifier attribute: #{attr}"
      end
    end

    def cookie(req)
      unless value = request.cookies[cookie_name]
        raise NoCookieError.new cookie_name
      end
      value
    end

    def rack_session(req)
      req.session[:init] = true
      req.session.id
    end

    def number_to_bucket(number)
      ('a'..'z').to_a[number]
    end
  end
end