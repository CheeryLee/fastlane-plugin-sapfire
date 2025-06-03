require "fastlane/action"
require_relative "../helper/ms_credentials"
require_relative "../helper/ms_devcenter_helper"
require_relative "../helper/azure_blob_helper"
require_relative "../msbuild/options"

module Fastlane
  module Actions
    class UploadPackageFlightAction < Action
      DEFAULT_TIMEOUT = 300

      def self.run(params)
        ms_credentials = Helper.ms_credentials
        app_id = params[:app_id]
        flight_name = params[:name]
        group_ids = params[:group_ids]
        path = params[:path]
        timeout = params.values.include?(:timeout) && params[:timeout].positive? ? params[:timeout] : DEFAULT_TIMEOUT

        UI.message("Acquiring authorization token for DevCenter ...")
        auth_token = Helper::MsDevCenterHelper.acquire_authorization_token(ms_credentials.tenant_id,
                                                                           ms_credentials.client_id,
                                                                           ms_credentials.client_secret,
                                                                           timeout)
        UI.message("Authorization token was obtained")
        UI.message("Creating package flight for app #{app_id} ...")

        flight_obj = Helper::MsDevCenterHelper.create_flight(app_id, flight_name, group_ids, auth_token, timeout)
        flight_id = flight_obj["flightId"]
        flight_name = flight_obj["friendlyName"]
        submission_id = flight_obj["pendingFlightSubmission"]["id"]
        submission_obj = Helper::MsDevCenterHelper.get_submission(app_id, flight_id, submission_id, auth_token, timeout)
        UI.message("Flight #{flight_name} (ID: #{flight_id}) created")

        UI.message("Prepare ZIP blob for upload ...")
        zip_path = Helper::AzureBlobHelper.create_blob_zip(File.expand_path(path))
        UI.success("Blob is ready")

        UI.message("Uploading ZIP blob ...")
        Helper::AzureBlobHelper.upload_blob(submission_obj["fileUploadUrl"], zip_path, timeout)
        UI.success("ZIP blob uploaded successfully")

        publish_immediate = params.values.include?(:publish_immediate) && [true].include?(params[:publish_immediate])
        submission_obj = prepare_empty_submission(submission_obj, publish_immediate)
        submission_obj = add_package_to_submission(submission_obj, File.basename(path))

        UI.message("Updating submission data ...")
        Helper::MsDevCenterHelper.update_submission(app_id, submission_obj, auth_token, timeout)
        UI.message("Updated successfully")

        UI.message("Committing ...")
        Helper::MsDevCenterHelper.commit_submission(app_id, flight_id, submission_id, auth_token, timeout)

        if params.values.include?(:skip_waiting_for_build_processing) &&
           [true].include?(params[:skip_waiting_for_build_processing])
          UI.success("Submission passed, but build processing were skipped. Check the Dev Center page to get an actual status.")
          return
        end

        status = false
        data = nil
        until status
          UI.message("Waiting for the submission to change the status - this may take a few minutes")
          data = Helper::MsDevCenterHelper.get_submission_status(app_id, flight_id, submission_id, auth_token, timeout)
          status = data["status"] != "CommitStarted"
          sleep(30) unless status
        end

        if data["status"] == "CommitFailed"
          errors = data["statusDetails"]["errors"]
          if errors.length == 1 && errors[0]["code"] == "InvalidState"
            UI.important(
              [
                "All submission operations passed correctly, but there are some things that you need to proceed using DevCenter.",
                "Message: #{errors[0]["details"]}"
              ].join("\n")
            )
            return
          end

          errors.each do |error|
            UI.error("Error code: #{error["code"]}\nMessage: #{error["details"]}")
          end

          UI.user_error!("Submission failed")
        end

        UI.success("Submission passed. Check the DevCenter page.")
      end

      def self.description
        "Creates a new package flight submission in Microsoft Partner Center and uploads new binary to it"
      end

      def self.authors
        ["CheeryLee"]
      end

      def self.is_supported?(platform)
        [:windows].include?(platform)
      end

      def self.output
        [
          ["SF_PUSHING_TIMEOUT", "The timeout for pushing to a server in seconds"],
          ["SF_APP_ID", "The Microsoft Store ID of an application"],
          ["SF_FLIGHT_NAME", "An optional name that would be used as a flight name"],
          ["SF_PACKAGE", "The file path to the package to be uploaded"]
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :timeout,
            env_name: "SF_PUSHING_TIMEOUT",
            description: "The timeout for pushing to a server in seconds",
            optional: true,
            default_value: 0,
            type: Integer
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_id,
            env_name: "SF_APP_ID",
            description: "The Microsoft Store ID of an application",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("The Microsoft Store ID can't be empty") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :skip_waiting_for_build_processing,
            description: "If set to true, the action will only commit the submission and skip the remaining build validation",
            optional: true,
            default_value: false,
            type: Fastlane::Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :publish_immediate,
            description: "If set to true, the submission will be published automatically once the validation passes",
            optional: true,
            default_value: false,
            type: Fastlane::Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :name,
            env_name: "SF_FLIGHT_NAME",
            description: "An optional name that would be used as a flight name",
            optional: true,
            default_value: "",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :group_ids,
            description: "A list of tester groups who will get a new package",
            optional: false,
            type: Array,
            verify_block: proc do |array|
              UI.user_error!("List of tester groups can't be empty") if array.empty?

              array.each do |value|
                UI.user_error!("Tester group ID must be a string and can't be null or empty") if
                  !value.is_a?(String) || value.nil? || value.empty?
              end
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :path,
            env_name: "SF_PACKAGE",
            description: "The file path to the package to be uploaded",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Path to UWP package is invalid") unless value && !value.empty?

              format_valid = false
              Msbuild::Options::PACKAGE_FORMATS.each do |extension|
                if value.end_with?(extension)
                  format_valid = true
                  break
                end
              end

              UI.user_error!("The provided path doesn't point to UWP file") unless
                File.exist?(File.expand_path(value)) && format_valid
            end
          )
        ]
      end

      def self.category
        :beta
      end

      def self.add_package_to_submission(submission_obj, file_name)
        check_submission(submission_obj)
        UI.user_error!("Package file name can't be null or empty") if file_name.nil? || file_name.empty?

        key = "flightPackages"
        package = {
          "fileName": file_name,
          "fileStatus": "PendingUpload",
          "minimumDirectXVersion": "None",
          "minimumSystemRam": "None"
        }

        if submission_obj[key].empty?
          submission_obj[key] = []
        else
          submission_obj[key].each do |existing_package|
            existing_package["fileStatus"] = "PendingDelete"
          end
        end

        submission_obj[key].append(package)
        submission_obj
      end

      def self.prepare_empty_submission(submission_obj, publish_immediate)
        check_submission(submission_obj)
        submission_obj["targetPublishMode"] = publish_immediate ? "Immediate" : "Manual"
        submission_obj
      end

      def self.check_submission(submission_obj)
        UI.user_error!("Submission data object need to be provided") if submission_obj.nil?
      end

      private_constant(:DEFAULT_TIMEOUT)
    end
  end
end
