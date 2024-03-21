require "fastlane/action"
require_relative "../helper/ms_credentials"

module Fastlane
  module Actions
    module SharedValues
      SF_MS_CREDENTIALS = :SF_MS_CREDENTIALS
    end

    class MsCredentialsAction < Action
      def self.run(params)
        Helper.ms_credentials.username = params[:username]
        Helper.ms_credentials.password = params[:password]
        Helper.ms_credentials.tenant_id = params[:tenant_id]
        Helper.ms_credentials.client_id = params[:client_id]
        Helper.ms_credentials.client_secret = params[:client_secret]

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

      def self.output
        [
          ["SF_MS_USERNAME", "The username of Azure AD account"],
          ["SF_MS_PASSWORD", "The password of Azure AD account"],
          ["SF_MS_TENANT_ID", "The unique identifier of the Azure AD instance"],
          ["SF_MS_CLIENT_ID", "The ID of an application that would be associate to get working with Microsoft account"],
          ["SF_MS_CLIENT_SECRET", "The unique secret string of an application that can be generated in Microsoft Partner Center"]
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :username,
            env_name: "SF_MS_USERNAME",
            description: "The username of Azure AD account",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Microsoft username can't be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :password,
            env_name: "SF_MS_PASSWORD",
            description: "The password of Azure AD account",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Microsoft password can't be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :tenant_id,
            env_name: "SF_MS_TENANT_ID",
            description: "The unique identifier of the Azure AD instance",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Tenant ID can't be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :client_id,
            env_name: "SF_MS_CLIENT_ID",
            description: "The ID of an application that would be associate to get working with Microsoft account",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Client ID can't be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :client_secret,
            env_name: "SF_MS_CLIENT_SECRET",
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
