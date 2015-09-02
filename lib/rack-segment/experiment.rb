module RackSegment
  class Experiment
    attr_reader :name, :traffic

    def initialize(name, buckets, traffic)
      @name = name
      @buckets = buckets.reduce({}) { |all, bucket| all[bucket.name] = bucket; all }
      @traffic = traffic
    end

    def bucket_count
      @buckets.count
    end

    def bucket(request)
      bucket_name = (request.headers[Middleware::HTTP_HEADER_PREFIX + name.upcase] || 'a').to_sym
      bucket_name = :a if bucket_name == :excluded
      bucket = @buckets[bucket_name]
      raise BucketNotFoundError.new(@bucket) unless bucket
      bucket.try(:call) || bucket
    end

    class << self
      def collection
        @collection ||= {}
      end

      def list
        collection.values
      end

      def [](name)
        experiment = collection[name.to_sym]
        raise ExperimentNotFoundError.new(name) unless experiment
        experiment
      end
    end
  end
end