require "fastlane/action"

module Fastlane
  module Actions
    class AssociateMsStoreAction < Action
      XML_NAME = "Package.StoreAssociation.xml".freeze

      def self.run(params)
        FastlaneCore::PrintTable.print_values(config: params, title: "Summary for associate_ms_store")

        begin
          UI.message("Creating #{XML_NAME}...")
          create_xml(params)
          UI.message("#{XML_NAME} successfully created")
        rescue StandardError => ex
          UI.user_error!("Something went wrong while associating the project: #{ex}")
        end
      end

      def self.create_xml(params)
        package_identity = params[:package_identity]
        manifest_path = File.expand_path(params[:manifest])
        appxmanifest_xml = get_appxmanifest_xml(manifest_path)

        display_name = get_display_name(appxmanifest_xml)
        UI.message("Display name: #{display_name}")

        UI.message("Update identity name to #{package_identity}")
        appxmanifest_xml = update_identity_name(appxmanifest_xml, package_identity)
        save_xml(appxmanifest_xml, manifest_path)

        document = REXML::Document.new
        document.xml_decl.version = "1.0"
        document.xml_decl.encoding = "utf-8"

        store_association = document.add_element("StoreAssociation", {
          "xmlns" => "http://schemas.microsoft.com/appx/2010/storeassociation"
        })
        store_association.add_element("Publisher").text = params[:publisher]
        store_association.add_element("PublisherDisplayName").text = params[:publisher_name]
        store_association.add_element("DeveloperAccountType").text = "WSA"
        store_association.add_element("GeneratePackageHash").text = "http://www.w3.org/2001/04/xmlenc#sha256"

        product_reserved_info = store_association.add_element("ProductReservedInfo")
        product_reserved_info.add_element("MainPackageIdentityName").text = package_identity

        reserved_names = product_reserved_info.add_element("ReservedNames")
        reserved_names.add_element("ReservedName").text = display_name

        working_directory = File.dirname(manifest_path)
        path = File.join(working_directory, XML_NAME)
        save_xml(document, path)
      end

      def self.get_appxmanifest_xml(manifest_path)
        file = File.open(manifest_path, "r")

        begin
          document = REXML::Document.new(file)
          file.close
          document
        rescue REXML::ParseException => ex
          UI.user_error!("Can't parse Package.appxmanifest: #{ex}")
        end
      end

      def self.save_xml(document, path)
        file = File.open(path, "w")
        document.write(file)
        file.close
      end

      def self.get_display_name(appxmanifest)
        begin
          display_name = appxmanifest.elements["Package"]
                                     .elements["Properties"]
                                     .elements["DisplayName"]
          display_name.text
        rescue REXML::ParseException => ex
          UI.user_error!("Can't find Package.Properties.DisplayName property in manifest: #{ex}")
        end
      end

      def self.update_identity_name(appxmanifest, name)
        begin
          identity = appxmanifest.elements["Package"]
                                 .elements["Identity"]
          identity.attributes["Name"] = name
          appxmanifest
        rescue StandardError => ex
          UI.user_error!("Can't update Package.Identity attribute `Name` in manifest: #{ex}")
        end
      end

      def self.description
        "Makes a local app manifest needed for Microsoft Store association"
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
            key: :manifest,
            description: "Path to the APPX package manifest",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Path to the APPX package manifest is invalid") unless value && !value.empty?
              UI.user_error!("The provided path doesn't point to AppxManifest-file") unless File.exist?(value) && value.end_with?(".appxmanifest")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :publisher,
            description: "Describes the publisher information. It must match the publisher subject information of the certificate used to sign a package",
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :publisher_name,
            description: "A friendly name for the publisher that can be displayed to users",
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :package_identity,
            description: "An unique name for the package",
            optional: false,
            type: String
          )
        ]
      end

      def self.category
        :project
      end
    end
  end
end
