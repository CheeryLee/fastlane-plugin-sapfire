require "fastlane_core/configuration/config_item"
require_relative "module"

module Msbuild
  class Options
    def self.available_options
      return @options if @options

      @options = plain_options
    end

    def self.plain_options
      [
        FastlaneCore::ConfigItem.new(
          key: :project,
          description: "Path to the SLN-solution file",
          optional: false,
          type: String,
          verify_block: proc do |value|
            UI.user_error!("Path to SLN-file is invalid") unless value && !value.empty?
            UI.user_error!("The provided path doesn't point to SLN-file") unless
              File.exist?(File.expand_path(value)) && value.end_with?(".sln")
          end
        ),
        FastlaneCore::ConfigItem.new(
          key: :configuration,
          description: "Build configuration",
          optional: false,
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :platform,
          description: "Target platform",
          optional: false,
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :restore,
          description: "Restore project prior to build the actual targets",
          optional: true,
          default_value: false,
          type: Fastlane::Boolean
        ),
        FastlaneCore::ConfigItem.new(
          key: :clean,
          description: "Should the project be cleaned before building it?",
          optional: true,
          default_value: false,
          type: Fastlane::Boolean
        ),
        FastlaneCore::ConfigItem.new(
          key: :appx_output_path,
          description: "Defines the folder to store the generated package artifacts. Relative path is a root folder where project is located",
          optional: true,
          default_value: "",
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :appx_bundle_platforms,
          description: [
            "Enables you to define the platforms to include in the bundle.",
            "It's possible to define multiple platforms divided by vertical line, e.g. 'x86|ARM'"
          ].join("\n"),
          optional: false,
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :build_mode,
          description: "Package build mode. Use `SideloadOnly` for sideloading only or `StoreUpload` for generating the .msixupload/.appxupload file",
          optional: false,
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :skip_codesigning,
          description: "Build without package signing",
          optional: true,
          default_value: false,
          type: Fastlane::Boolean
        ),
        FastlaneCore::ConfigItem.new(
          key: :jobs,
          description: [
            "A number of concurrent processes to use when building.",
            "Set it to -1 if you want to use up to the number of processors in the computer"
          ].join("\n"),
          optional: true,
          default_value: 1,
          type: Integer,
          verify_block: proc do |value|
            UI.important("A number of parallel jobs can't equals to zero. Using default value.") if value.zero?
          end
        ),
        FastlaneCore::ConfigItem.new(
          key: :properties,
          description: "A hash of project properties to be set up, where the key is a property name and the value is it's value",
          optional: true,
          default_value: {},
          type: Hash,
          verify_block: proc do |value|
            counter = 0

            value.each do |key, _|
              UI.user_error!("Item #{counter}: key type must be Symbol") unless key.is_a?(Symbol)
              counter += 1
            end
          end
        )
      ]
    end

    public_class_method(:available_options)
    private_class_method(:plain_options)
  end
end
