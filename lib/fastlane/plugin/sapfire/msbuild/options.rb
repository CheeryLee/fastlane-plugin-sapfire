require "fastlane_core/configuration/config_item"
require_relative "module"

module Msbuild
  class Options
    PACKAGE_FORMATS = %w[.appx .appxbundle .appxupload .msix .msixbundle .msixupload].freeze

    def self.available_options
      return @options if @options

      @options = plain_options
    end

    def self.available_output
      return @output if @output

      @output = plain_output
    end

    def self.plain_output
      [
        ["SF_MSBUILD_PROJECT", "Path to the SLN-solution file"],
        ["SF_MSBUILD_CONFIGURATION", "Build configuration"],
        ["SF_MSBUILD_PLATFORM", "Target platform"],
        ["SF_MSBUILD_RESTORE", "Restore project prior to build the actual targets"],
        ["SF_MSBUILD_CLEAN", "Should the project be cleaned before building it?"],
        ["SF_MSBUILD_APPX_OUTPUT_PATH", "Defines the folder to store the generated package artifacts. Relative path is a root folder where project is located"],
        ["SF_MSBUILD_APPX_OUTPUT_NAME", "Defines the name of the resulting package"],
        ["SF_MSBUILD_APPX_PLATFORMS", [
          "Enables you to define the platforms to include in the bundle.",
          "It's possible to define multiple platforms divided by vertical line, e.g. 'x86|ARM'"
        ].join("\n")],
        ["SF_MSBUILD_BUILD_MODE", "Package build mode. Use `SideloadOnly` for sideloading only or `StoreUpload` for generating the .msixupload/.appxupload file"],
        ["SF_MSBUILD_SKIP_CODESIGNING", "Build without package signing"],
        ["SF_MSBUILD_JOBS_COUNT", [
          "A number of concurrent processes to use when building.",
          "Set it to -1 if you want to use up to the number of processors in the computer"
        ].join("\n")]
      ]
    end

    def self.plain_options
      [
        FastlaneCore::ConfigItem.new(
          key: :project,
          env_name: "SF_MSBUILD_PROJECT",
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
          env_name: "SF_MSBUILD_CONFIGURATION",
          description: "Build configuration",
          optional: false,
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :platform,
          env_name: "SF_MSBUILD_PLATFORM",
          description: "Target platform",
          optional: false,
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :restore,
          env_name: "SF_MSBUILD_RESTORE",
          description: "Restore project prior to build the actual targets",
          optional: true,
          default_value: false,
          type: Fastlane::Boolean
        ),
        FastlaneCore::ConfigItem.new(
          key: :clean,
          env_name: "SF_MSBUILD_CLEAN",
          description: "Should the project be cleaned before building it?",
          optional: true,
          default_value: false,
          type: Fastlane::Boolean
        ),
        FastlaneCore::ConfigItem.new(
          key: :appx_output_path,
          env_name: "SF_MSBUILD_APPX_OUTPUT_PATH",
          description: "Defines the folder to store the generated package artifacts. Relative path is a root folder where project is located",
          optional: true,
          default_value: "",
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :appx_output_name,
          env_name: "SF_MSBUILD_APPX_OUTPUT_NAME",
          description: "Defines the name of the resulting package",
          optional: true,
          default_value: "",
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :appx_bundle_platforms,
          env_name: "SF_MSBUILD_APPX_PLATFORMS",
          description: [
            "Enables you to define the platforms to include in the bundle.",
            "It's possible to define multiple platforms divided by vertical line, e.g. 'x86|ARM'"
          ].join("\n"),
          optional: false,
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :build_mode,
          env_name: "SF_MSBUILD_BUILD_MODE",
          description: "Package build mode. Use `SideloadOnly` for sideloading only or `StoreUpload` for generating the .msixupload/.appxupload file",
          optional: false,
          type: String
        ),
        FastlaneCore::ConfigItem.new(
          key: :skip_codesigning,
          env_name: "SF_MSBUILD_SKIP_CODESIGNING",
          description: "Build without package signing",
          optional: true,
          default_value: false,
          type: Fastlane::Boolean
        ),
        FastlaneCore::ConfigItem.new(
          key: :jobs,
          env_name: "SF_MSBUILD_JOBS_COUNT",
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
