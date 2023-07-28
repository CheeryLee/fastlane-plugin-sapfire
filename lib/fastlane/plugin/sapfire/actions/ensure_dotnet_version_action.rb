require "open3"
require_relative "../helper/sapfire_helper"

module Fastlane
  module Actions
    class EnsureDotnetVersionAction < Action
      def self.run(params)
        UI.user_error!("Can't find dotnet") unless Helper::SapfireHelper.dotnet_specified?

        dotnet_path = Actions.lane_context[SharedValues::SF_DOTNET_PATH]
        cmd = "\"#{dotnet_path}\" --list-sdks"

        UI.command(cmd)
        stdin, stdout = Open3.popen2(cmd)
        output = stdout.read
        stdin.close
        stdout.close

        versions = output.split("\n")
        available_versions = []
        current_version = nil
        required_version = nil
        found = false

        begin
          required_version = Gem::Version.new(params[:version])
        rescue ArgumentError => ex
          UI.user_error!("Invalid version number provided, make sure it's valid: #{ex}")
        end

        required_version_numbers = required_version.to_s.split(".")

        versions.each do |value|
          path_bracket_index = value.index("[")

          begin
            ver_number = value[0..path_bracket_index - 1].strip
            current_version = Gem::Version.new(ver_number)
            available_versions.append(current_version.to_s)
          rescue ArgumentError => ex
            UI.user_error!("Can't parse the version entry from dotnet output: #{ex}")
          end

          if params[:strict]
            next unless current_version == required_version

            success(required_version)
          else
            current_version_numbers = current_version.to_s.split(".")
            all_correct = true

            required_version_numbers.each_with_index do |required_version_number, index|
              current_version_number = current_version_numbers[index]
              next if required_version_number == current_version_number

              all_correct = false
              break
            end

            next unless all_correct

            success(current_version)
          end

          found = true
          break
        end

        error(required_version, available_versions) unless found
      end

      def self.success(version)
        UI.success("Required .NET version has found: #{version}")
      end

      def self.error(version, available_versions)
        str = [
          "Required .NET version hasn't been found: #{version}",
          "Available versions: #{available_versions}"
        ].join("\n")

        UI.user_error!(str)
      end

      def self.description
        "Ensures the right version of .NET is installed and can be used"
      end

      def self.authors
        ["CheeryLee"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.output
        [
          ["SF_ENSURE_DOTNET_VERSION", ".NET version to verify that is installed"]
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :version,
            env_name: "SF_ENSURE_DOTNET_VERSION",
            description: ".NET version to verify that is installed",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("The version of .NET to check is empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :strict,
            description: "Should the version be verified strictly (all 3 version numbers), or matching only the given version numbers (i.e. 6.0 == 6.0.x)",
            optional: true,
            default_value: true,
            type: Boolean
          )
        ]
      end

      def self.category
        :building
      end
    end
  end
end
