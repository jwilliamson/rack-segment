module RackSegment
  class RailTie < Rails::Railtie
    rake_tasks do
      # load File.join(File.dirname(__FILE__), "../../tasks/rack_data_capture.rake")
    end

    config.to_prepare do
      # load RackDataCaptureRailTie::config_path if RackDataCaptureRailTie::config_exists?
    end

    class << self
      # def config_path 
      #   @config_path ||= File.join Rails.root, 'config/rack_data_capture.rb'
      # end

      # def config_exists?
      #   File.exists? config_path
      # end
    end
  end
end