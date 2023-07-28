require "fastlane/action"
require_relative "../helper/sapfire_helper"

module Fastlane
  module Actions
    class AppCertificationAction < Action
      def self.run(params)
        path = Helper::SapfireHelper.kits_10_location
        UI.user_error!("Can't locate Windows SDK. Ensure it's installed.") if path.empty?
        UI.message("Windows SDK path: #{path}")

        appcert_path = File.join(path, "App Certification Kit/appcert.exe")
        UI.user_error!("Can't find appcert.exe. Check your Windows SDK installation.") unless File.exist?(appcert_path)

        cmd = "\"#{appcert_path}\" reset"
        UI.command(cmd)
        wait_thr = run_appcert(cmd)
        UI.user_error!("Appcert reset failed. See the log above.") unless wait_thr.value.success?

        cmd = "\"#{appcert_path}\" test -appxpackagepath \"#{params[:appx_package_path]}\" -reportoutputpath \"#{params[:output_path]}\""
        UI.command(cmd)
        wait_thr = run_appcert(cmd)
        UI.user_error!("Appcert checking failed. See the log above.") unless wait_thr.value.success?
        UI.success("App checking has successfully finished. Output result saved at: #{params[:output_path]}") if wait_thr.value.success?
      end

      def self.description
        "Runs Windows App Certification Kit to ensure your app is safe and efficient before publishing it to Microsoft Store"
      end

      def self.authors
        ["CheeryLee"]
      end

      def self.is_supported?(platform)
        [:windows].include?(platform)
      end

      def self.output
        [
          ["SF_PACKAGE", "The full path to a UWP package"],
          ["SF_WACK_OUTPUT_PATH", "The path where to save report output XML-file"]
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :appx_package_path,
            env_name: "SF_PACKAGE",
            description: "The full path to a UWP package",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Path to UWP package is invalid") unless value && !value.empty?
              UI.user_error!("The provided path doesn't point to APPX-file") unless
                File.exist?(File.expand_path(value)) && value.end_with?(".appx")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :output_path,
            env_name: "SF_WACK_OUTPUT_PATH",
            description: "The path where to save report output XML-file",
            optional: false,
            type: String
          )
        ]
      end

      def self.category
        :testing
      end

      def self.run_appcert(cmd)
        Open3.popen2(cmd) do |_, stdout, wait_thr|
          until stdout.eof?
            stdout.each do |l|
              line = l.force_encoding("utf-8").chomp
              puts line
            end
          end

          wait_thr
        end
      end
    end
  end
end
