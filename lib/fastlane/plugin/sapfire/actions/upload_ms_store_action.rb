require "fastlane/action"
require_relative "../helper/ms_credentials"
require_relative "../helper/ms_devcenter_helper"
require_relative "../msbuild/options"

module Fastlane
  module Actions
    class UploadMsStoreAction < Action
      DEFAULT_TIMEOUT = 300

      def self.run(params)
        ms_credentials = Helper.ms_credentials
        app_id = params[:app_id]
        path = params[:path]
        timeout = params.values.include?(:timeout) && params[:timeout].positive? ? params[:timeout] : DEFAULT_TIMEOUT

        UI.message("Acquiring authorization token for DevCenter ...")
        auth_token = Helper::MsDevCenterHelper.acquire_authorization_token(ms_credentials.tenant_id,
                                                                           ms_credentials.client_id,
                                                                           ms_credentials.client_secret,
                                                                           timeout)
        UI.message("Authorization token was obtained")

        UI.message("Creating submission for app #{app_id} ...")
        pending_submission = Helper::MsDevCenterHelper.non_published_submission(app_id, auth_token, timeout)
        submission_id = pending_submission["id"]

        unless pending_submission.nil?
          if params.values.include?(:remove_pending_submission) &&
             [true].include?(params[:remove_pending_submission])
            UI.message("Pending submission #{submission_id} were found and scheduled for deletion due to 'remove_pending_submission' argument set to 'true'")
            Helper::MsDevCenterHelper.remove_submission(app_id, submission_id, auth_token, timeout)
            UI.message("Pending submission deleted")
          else
            UI.user_error!([
              "There is a pending submission #{submission_id} has already been created.",
              "You need to either proceed it or remove before creating a new one.",
              "Set 'remove_pending_submission' argument to 'true' to do that automatically."
            ].join(" "))
          end
        end

        submission_obj = Helper::MsDevCenterHelper.create_submission(app_id, auth_token, timeout)
        submission_id = submission_obj["id"]
        UI.message("Submission #{submission_id} created")

        UI.message("Prepare ZIP blob for upload ...")
        zip_path = create_blob_zip(File.expand_path(path))
        UI.success("Blob is ready")

        UI.message("Uploading ZIP blob ...")
        Helper::MsDevCenterHelper.upload_blob(submission_obj["fileUploadUrl"], zip_path, timeout)
        UI.success("ZIP blob uploaded successfully")

        submission_obj = prepare_empty_submission(submission_obj)
        submission_obj = add_package_to_submission(submission_obj, File.basename(path))

        UI.message("Updating submission data ...")
        Helper::MsDevCenterHelper.update_submission(app_id, submission_obj, auth_token, timeout)
        UI.message("Updated successfully")

        UI.message("Committing ...")
        Helper::MsDevCenterHelper.commit_submission(app_id, submission_id, auth_token, timeout)

        if params.values.include?(:skip_waiting_for_build_processing) &&
           [true].include?(params[:skip_waiting_for_build_processing])
          UI.success("Submission passed, but build processing were skipped. Check the Dev Center page.")
          return
        end

        status = false
        data = nil
        until status
          UI.message("Waiting for the submission to change the status - this may take a few minutes")
          data = Helper::MsDevCenterHelper.get_submission_status(app_id, submission_id, auth_token, timeout)
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
        "Uploads new binary to Microsoft Partner Center"
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
            key: :remove_pending_submission,
            description: "If set to true, the pending submission halts - a new one will be created automatically",
            optional: true,
            default_value: false,
            type: Fastlane::Boolean
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
        :production
      end

      def self.create_blob_zip(package_path)
        zip_path = File.join(File.dirname(package_path), "blob.zip")
        File.delete(zip_path) if File.exist?(zip_path)

        Zip::File.open(zip_path, create: true) do |file|
          file.add(File.basename(package_path), package_path)

          screenshot_path = File.join(Helper::SapfireHelper.root_plugin_location, "assets", "ms_example_screenshot.png")
          file.add("ms_example_screenshot.png", File.expand_path(screenshot_path))
        end

        zip_path
      end

      def self.add_package_to_submission(submission_obj, file_name)
        check_submission(submission_obj)
        UI.user_error!("Package file name can't be null or empty") if file_name.nil? || file_name.empty?

        key = "applicationPackages"
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

      def self.prepare_empty_submission(submission_obj)
        check_submission(submission_obj)

        submission_obj["applicationCategory"] = "UtilitiesAndTools" if submission_obj["applicationCategory"] == "NotSet"
        submission_obj["targetPublishMode"] = "Manual"

        if submission_obj["allowTargetFutureDeviceFamilies"].empty?
          submission_obj["allowTargetFutureDeviceFamilies"] = {
            "Desktop": false,
            "Mobile": false,
            "Holographic": false,
            "Xbox": false
          }
        end

        if submission_obj["listings"].empty?
          submission_obj["listings"]["en-us"] = {}
          submission_obj["listings"]["en-us"]["baseListing"] = {
            "description": "1",
            "privacyPolicy": "https://example.com",
            "images": [
              {
                "fileName": "ms_example_screenshot.png",
                "fileStatus": "PendingUpload",
                "imageType": "Screenshot"
              }
            ]
          }
        end

        submission_obj
      end

      def self.check_submission(submission_obj)
        UI.user_error!("Submission data object need to be provided") if submission_obj.nil?
      end

      private_constant(:DEFAULT_TIMEOUT)
    end
  end
end
