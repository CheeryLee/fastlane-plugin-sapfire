require "fastlane/action"
require_relative "../actions_base/msbuild_action_base"

module Fastlane
  module Actions
    class BuildUwpAppAction < MsbuildActionBase
      def self.run(params)
        Msbuild.config.certificate = Actions.lane_context[SharedValues::SF_CERTIFICATE_PATH]
        Msbuild.config.certificate_password = Actions.lane_context[SharedValues::SF_CERTIFICATE_PASSWORD]
        Msbuild.config.certificate_thumbprint = Actions.lane_context[SharedValues::SF_CERTIFICATE_THUMBPRINT]
        Msbuild.config.build_type = Msbuild::BuildType::UWP

        super(params)
      end

      def self.overwritten_msbuild_properties
        props = {
          AppxPackageDir: "appx_output_path",
          AppxBundlePlatforms: "appx_bundle_platforms",
          UapAppxPackageBuildMode: "build_mode",
          AppxPackageSigningEnabled: "skip_codesigning"
        }
        super.merge(props)
      end

      def self.description
        "Alias for the `msbuild` action with additional parameters for UWP"
      end

      def self.details
        [
          "Works only on `windows` platform.",
          "The `:platform` value must contain the same value as `:appx_bundle_platforms` does.",
          "If `appx_bundle_platforms` is set to be multiplatform, then any of platforms from it's list must be set in the `:platform` option"
        ].join("\n")
      end

      def self.authors
        ["CheeryLee"]
      end

      def self.is_supported?(platform)
        [:windows].include?(platform)
      end

      def self.rejected_options
        nil
      end

      def self.category
        :building
      end
    end
  end
end
