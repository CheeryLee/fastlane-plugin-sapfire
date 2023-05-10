require "fastlane/action"

module Fastlane
  module Actions
    module SharedValues
      SF_MS_USERNAME = :SF_MS_USERNAME
      SF_MS_PASSWORD = :SF_MS_PASSWORD
      SF_MS_TENANT_ID = :SF_MS_TENANT_ID
      SF_MS_CLIENT_ID = :SF_MS_CLIENT_ID
      SF_MS_CLIENT_SECRET = :SF_MS_CLIENT_SECRET
    end

    class MsCredentialsAction < Action
      def self.run(params)
        Actions.lane_context[SharedValues::SF_MS_USERNAME] = params[:username]
        Actions.lane_context[SharedValues::SF_MS_PASSWORD] = params[:password]
        Actions.lane_context[SharedValues::SF_MS_TENANT_ID] = params[:tenant_id]
        Actions.lane_context[SharedValues::SF_MS_CLIENT_ID] = params[:client_id]
        Actions.lane_context[SharedValues::SF_MS_CLIENT_SECRET] = params[:client_secret]

        UI.success("Credentials for Azure AD account is successfully saved for further actions")
      end

      def self.description
        "Sets Azure AD account credentials"
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
            key: :username,
            description: "The username of Azure AD account",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Microsoft username can't be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :password,
            description: "The password of Azure AD account",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Microsoft password can't be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :tenant_id,
            description: "The unique identifier of the Azure AD instance",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Tenant ID can't be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :client_id,
            description: "The ID of an application that would be associate to get working with Microsoft account",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Client ID can't be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :client_secret,
            description: "The unique secret string of an application that can be generated in Microsoft Partner Center",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Client secret string can't be empty") unless value && !value.empty?
            end
          )
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
