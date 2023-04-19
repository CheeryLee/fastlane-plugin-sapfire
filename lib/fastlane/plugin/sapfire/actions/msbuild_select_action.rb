require "fastlane/action"
require_relative "../msbuild/module"

module Fastlane
  module Actions
    module SharedValues
      SF_MSBUILD_PATH = :SF_MSBUILD_PATH
      SF_MSBUILD_TYPE = :SF_MSBUILD_TYPE
    end

    class MsbuildSelectAction < Action
      def self.run(params)
        path = (params || []).first.to_s
        path = File.expand_path(path)

        UI.user_error!("File '#{path}' doesn't exist") unless File.exist?(path)
        UI.user_error!("Path to MSBuild executable or library required") if
          path.empty? || (!path.end_with?("MSBuild.exe") && !path.end_with?("MSBuild.dll"))

        Actions.lane_context[SharedValues::SF_MSBUILD_PATH] = path
        Actions.lane_context[SharedValues::SF_MSBUILD_TYPE] = if path.end_with?("MSBuild.exe")
                                                                Msbuild::MsbuildType::EXE
                                                              else
                                                                Msbuild::MsbuildType::LIBRARY
                                                              end

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
