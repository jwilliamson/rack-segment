module RackSegment
  class Experiment
    attr_reader :name

    def initialize(name, buckets)
      @name = name
      @buckets = buckets.reduce({}) { |all, bucket| all[bucket.name] = bucket; all }
    end

    def bucket_count
      @buckets.count
    end

    def bucket(request)
      bucket = @buckets[(request.headers[Middleware::HTTP_HEADER_PREFIX + name.upcase] || 'a').to_sym]
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