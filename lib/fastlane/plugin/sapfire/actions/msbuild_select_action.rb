require "fastlane/action"

module Fastlane
  module Actions
    module SharedValues
      SF_MSBUILD_PATH = :SF_MSBUILD_PATH
    end

    class MsbuildSelectAction < Action
      def self.run(params)
        path = (params || []).first.to_s

        UI.user_error!("Path to MSBuild executable required") if path.empty? || !path.end_with?("MSBuild.exe")
        UI.user_error!("File '#{path}' doesn't exist") unless File.exist?(path)

        Actions.lane_context[SharedValues::SF_MSBUILD_PATH] = path

        UI.message("Setting MSBuild executable to '#{path}' for all next build steps")
      end

      def self.description
        "Changes the MSBuild executable to use. Useful if you have multiple installed versions."
      end

      def self.authors
        ["CheeryLee"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'msbuild_select("/cygdrive/c/Program\ Files/Microsoft\ Visual\ Studio/2022/Community/Msbuild/Current/Bin/MSBuild.exe")'
        ]
      end

      def self.category
        :building
      end
    end
  end
end
