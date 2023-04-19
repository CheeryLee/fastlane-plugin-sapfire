require "fastlane/action"
require_relative "../helper/sapfire_helper"

module Fastlane
  module Actions
    class UploadNugetAction < Action
      def self.run(params)
        UI.user_error!("Can't find dotnet") unless Helper::SapfireHelper.dotnet_specified?

        dotnet_path = Actions.lane_context[SharedValues::SF_DOTNET_PATH]
        dotnet_args = get_dotnet_args(params)
        cmd = "\"#{dotnet_path}\" nuget push #{dotnet_args.join(" ")}"

        UI.command(cmd)

        Open3.popen2(cmd) do |_, stdout, wait_thr|
          until stdout.eof?
            stdout.each do |l|
              line = l.force_encoding("utf-8").chomp
              puts line
            end
          end

          UI.user_error!("NuGet package pushing failed. See the log above.") unless wait_thr.value.success?
          UI.success("Package has successfully uploaded") if wait_thr.value.success?
        end
      end

      def self.description
        "Pushes a package to the server and publishes it"
      end

      def self.authors
        ["CheeryLee"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :api_key,
            description: "The API key for the server",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("The API key for the server must be specified and must not be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :source,
            description: "The server URL. NuGet identifies a UNC or local folder source and simply copies the file there instead of pushing it using HTTP",
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :timeout,
            description: "The timeout for pushing to a server in seconds",
            optional: true,
            default_value: 0,
            type: Integer
          ),
          FastlaneCore::ConfigItem.new(
            key: :path,
            description: "The file path to the package to be uploaded",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Path to NuGet package is invalid") unless value && !value.empty?
              UI.user_error!("The provided path doesn't point to NUPKG-file") unless
                File.exist?(File.expand_path(value)) && value.end_with?(".nupkg")
            end
          )
        ]
      end

      def self.category
        :production
      end

      def self.get_dotnet_args(params)
        args = []

        args.append(params[:path])
        args.append("--api-key #{params[:api_key]}")
        args.append("--source #{params[:source]}")
        args.append("--timeout #{params[:timeout]}")

        args
      end
    end
  end
end
