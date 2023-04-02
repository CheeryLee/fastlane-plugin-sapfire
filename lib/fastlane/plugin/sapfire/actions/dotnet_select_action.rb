require "fastlane/action"

module Fastlane
  module Actions
    module SharedValues
      SF_DOTNET_PATH = :SF_DOTNET_PATH
    end

    class DotnetSelectAction < Action
      def self.run(params)
        path = (params || []).first.to_s

        UI.user_error!("Path to dotnet executable required") if path.empty? || !path.end_with?("dotnet.exe")
        UI.user_error!("File '#{path}' doesn't exist") unless File.exist?(path)

        Actions.lane_context[SharedValues::SF_DOTNET_PATH] = path

        UI.message("Setting dotnet executable to '#{path}' for all next build steps")
      end

      def self.description
        "Changes the dotnet executable to use"
      end

      def self.authors
        ["CheeryLee"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'dotnet_select("C:/Program\ Files/dotnet/dotnet.exe")'
        ]
      end

      def self.category
        :building
      end
    end
  end
end
