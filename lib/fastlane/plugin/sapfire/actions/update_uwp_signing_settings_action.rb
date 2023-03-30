require "fastlane/action"

module Fastlane
  module Actions
    module SharedValues
      SF_CERTIFICATE_PATH = :SF_CERTIFICATE_PATH
      SF_CERTIFICATE_PASSWORD = :SF_CERTIFICATE_PASSWORD
      SF_CERTIFICATE_THUMBPRINT = :SF_CERTIFICATE_THUMBPRINT
    end

    class UpdateUwpSigningSettingsAction < Action
      def self.run(params)
        path = params[:certificate]

        Actions.lane_context[SharedValues::SF_CERTIFICATE_PATH] = path
        Actions.lane_context[SharedValues::SF_CERTIFICATE_PASSWORD] = params[:password]
        Actions.lane_context[SharedValues::SF_CERTIFICATE_THUMBPRINT] = params[:thumbprint]

        UI.message("Setting signing certificate to '#{path}' for all next build steps")
      end

      def self.description
        "Configures UWP package signing settings. Works only on 'windows' platform. Values that would be set in this action will be applied to all next actions."
      end

      def self.details
        "Works only on `windows` platform"
      end

      def self.authors
        ["CheeryLee"]
      end

      def self.is_supported?(platform)
        [:windows].include?(platform)
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :certificate,
            description: "Path to the certificate to use",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Path to certificate is invalid") unless value && !value.empty?
              UI.user_error!("The provided path doesn't point to PFX-file") unless File.exist?(value) && value.end_with?(".pfx")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :password,
            description: "The password for the private key in the certificate",
            optional: true,
            default_value: "",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :thumbprint,
            description: "This value must match the thumbprint in the signing certificate or be an empty string",
            optional: true,
            default_value: "",
            type: String
          )
        ]
      end

      def self.category
        :code_signing
      end
    end
  end
end
