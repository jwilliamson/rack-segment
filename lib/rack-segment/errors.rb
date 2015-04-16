module RackSegment
  BucketNotFoundError = Class.new(StandardError) do
    def initialize(bucket)
      super "No bucket '#{bucket}' found"
    end
  end

  ExperimentNotFoundError = Class.new(StandardError) do
    def initialize(experiment)
      super "No Experiment '#{experiment}' found"
    end
  end
end