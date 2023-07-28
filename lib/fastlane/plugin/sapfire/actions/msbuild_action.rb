require "fastlane/action"
require_relative "../msbuild/options"
require_relative "../msbuild/module"
require_relative "../actions_base/msbuild_action_base"

module Fastlane
  module Actions
    class MsbuildAction < MsbuildActionBase
      def self.run(params)
        Msbuild.config.certificate = nil
        Msbuild.config.certificate_password = nil
        Msbuild.config.certificate_thumbprint = nil
        Msbuild.config.build_type = Msbuild::BuildType::GENERIC

        super(params)
      end

      def self.description
        "Executes MSBuild to build the application"
      end

      def self.authors
        ["CheeryLee"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.rejected_options
        %i[
          appx_output_path
          appx_output_name
          appx_bundle_platforms
          build_mode
          skip_codesigning
        ]
      end

      def self.rejected_output
        %w[
          SF_MSBUILD_APPX_OUTPUT_PATH
          SF_MSBUILD_APPX_OUTPUT_NAME
          SF_MSBUILD_APPX_PLATFORMS
          SF_MSBUILD_BUILD_MODE
          SF_MSBUILD_SKIP_CODESIGNING
        ]
      end

      def self.category
        :building
      end
    end
  end
end
