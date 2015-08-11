module RackSegment
  class Middleware
    HTTP_HEADER_PREFIX = 'HTTP_EXPERIMENT_'

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
      identifier = retrieve_id(env)
      experiments.each { |e| write_headers identifier, env, e }

      status, headers, body = @app.call(env)
      debug_info(env, headers) if debug_mode?

      [status, headers, body]
    end

    private
    def write_headers(identifier, env, experiment)
      begin
        experiment_unique = Digest::SHA1.hexdigest(experiment.name).to_i(0x10)
        unique = experiment_unique + Digest::SHA1.hexdigest(identifier).to_i(0x10)
        env[HTTP_HEADER_PREFIX + experiment.name.upcase] = number_to_bucket(unique % experiment.bucket_count)
      rescue NoCookieError => e
        @log.info "No Cookie found called #{cookie_name}"
      rescue StandardError => e
        @log.info "Error when extracting identifier"
        raise e unless debug_mode?
      end
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

    def retrieve_id(env)
      case
        when identifier.respond_to?(:call)           then identifier.call(env)
        when identifier == :rack_session             then rack_session(env)
        when identifier == :cookie                   then cookie(env)
        else raise "Unsupported identifier attribute: #{attr}"
      end
    end

    def cookie(env)
      request = Rack::Request.new env
      unless value = request.cookies[cookie_name]
        raise NoCookieError.new cookie_name
      end
      value
    end

    def rack_session(env)
      request = Rack::Request.new env
      request.session[:init] = true
      request.session.id
    end

    def number_to_bucket(number)
      ('a'..'z').to_a[number]
    end
  end
end