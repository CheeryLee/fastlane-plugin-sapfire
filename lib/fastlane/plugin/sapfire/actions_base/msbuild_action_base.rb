require "fastlane/action"
require_relative "../msbuild/runner"
require_relative "../msbuild/options"
require_relative "../msbuild/module"

module Fastlane
  module Actions
    class MsbuildActionBase < Action
      def self.run(params)
        Msbuild.config.params = params
        Msbuild.config.msbuild_path = Fastlane::Actions.lane_context[SharedValues::SF_MSBUILD_PATH]
        Msbuild.config.overwritten_props = overwritten_msbuild_properties

        runner = Msbuild::Runner.new
        runner.run
      end

      def self.overwritten_msbuild_properties
        {
          Configuration: "configuration",
          Platform: "platform"
        }
      end

      def self.available_options
        rejected_options_array = rejected_options
        return Msbuild::Options.available_options if rejected_options_array.nil?

        Msbuild::Options.available_options.reject do |option|
          rejected_options_array.include?(option.key)
        end
      end
    end
  end
end
