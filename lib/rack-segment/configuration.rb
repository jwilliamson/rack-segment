module RackSegment
  class ConfigBuilder
    attr_reader :experiments

    def initialize
      @experiments = []
    end

    def experiment(name, traffic = 1, &block)
      builder = ExperimentBuilder.new
      builder.instance_eval &block
      @experiments << Experiment.new(name, builder.buckets, traffic)
    end
  end

  class ExperimentBuilder
    attr_reader :buckets

    def initialize
      @buckets = []
    end

    def variant(name, obj = nil, &block)
      @buckets << Bucket.new(name, obj || block)
    end
  end
end