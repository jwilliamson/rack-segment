require 'rake'

%w(
    version
    errors
    experiment
    bucket
    middleware
    configuration
  ).each do |f|
  require "rack-segment/#{f}"
end

module RackSegment
  extend self

  def config(&block)
    builder = ConfigBuilder.new 
    builder.instance_eval &block

    builder.experiments.each do |experiment|
      Experiment.collection[experiment.name.to_sym] = experiment
    end
    
  end
end

require 'rack-segment/rails_tie' if defined? Rails