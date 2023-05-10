require "uri"
require "net/http"
require "json"
require "fastlane/action"

module Fastlane
  module Actions
    class AssociateMsStoreAction < Action
      XML_NAME = "Package.StoreAssociation.xml".freeze

      def self.run(params)
        FastlaneCore::PrintTable.print_values(config: params, title: "Summary for associate_ms_store")

        begin
          UI.message("Creating #{XML_NAME}...")

          token = acquire_authorization_token
          developer_info = get_developer_info(token)
          app_info = get_app_info(token, params[:app_id])
          create_xml(params[:manifest], developer_info, app_info)

          UI.message("#{XML_NAME} successfully created")
        rescue StandardError => ex
          UI.user_error!("Something went wrong while associating the project: #{ex}")
        end
      end

      def self.create_xml(manifest_path, developer_info, app_info)
        app_identity = app_info[:identity]
        app_names = app_info[:names]
        publisher = developer_info[:publisher]
        publisher_display_name = developer_info[:display_name]
        appxmanifest_xml = get_appxmanifest_xml(manifest_path)

        UI.message("Set identity name: #{app_identity}")

        begin
          identity_entry = appxmanifest_xml.elements["Package"]
                                           .elements["Identity"]
          identity_entry.attributes["Name"] = app_identity
          identity_entry.attributes["Publisher"] = publisher

          properties_entry = appxmanifest_xml.elements["Package"]
                                             .elements["Properties"]
          properties_entry.elements["DisplayName"].text = app_names[0] unless app_names.empty?
          properties_entry.elements["PublisherDisplayName"].text = publisher_display_name
        rescue StandardError => ex
          UI.user_error!("Can't update app manifest: #{ex}")
        end

        save_xml(appxmanifest_xml, manifest_path)

        UI.message("Set publisher data: #{publisher}")
        UI.message("Set publisher display name: #{publisher_display_name}")

        document = REXML::Document.new
        document.xml_decl.version = "1.0"
        document.xml_decl.encoding = "utf-8"

        store_association = document.add_element("StoreAssociation", {
          "xmlns" => "http://schemas.microsoft.com/appx/2010/storeassociation"
        })
        store_association.add_element("Publisher").text = publisher
        store_association.add_element("PublisherDisplayName").text = publisher_display_name
        store_association.add_element("DeveloperAccountType").text = "WSA"
        store_association.add_element("GeneratePackageHash").text = "http://www.w3.org/2001/04/xmlenc#sha256"

        product_reserved_info = store_association.add_element("ProductReservedInfo")
        product_reserved_info.add_element("MainPackageIdentityName").text = app_identity

        reserved_names = product_reserved_info.add_element("ReservedNames")
        app_names.each do |x|
          reserved_names.add_element("ReservedName").text = x
        end

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

      def self.get_developer_info(token)
        UI.message("Obtaining developer info ...")

        headers = {
          "Authorization": "Bearer #{token}",
          "Accept": "application/json",
          "MS-Contract-Version": "1"
        }
        query = {
          setvar: "fltaad:1"
        }

        uri = URI("https://developer.microsoft.com/vsapi/developer")
        uri.query = URI.encode_www_form(query)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        request = Net::HTTP::Get.new(uri, headers)
        response = https.request(request)

        begin
          data = JSON.parse(response.body)

          if response.code == "200"
            UI.message("Developer info was obtained")
            return {
              display_name: data["PublisherDisplayName"],
              publisher: data["Publisher"]
            }
          end

          UI.user_error!("Request returned the error: #{response.code}")
        rescue StandardError => ex
          UI.user_error!("Developer info request failed: #{ex}")
        end
      end

      def self.get_app_info(token, app_id)
        UI.message("Obtaining application info ...")

        headers = {
          "Authorization": "Bearer #{token}",
          "Accept": "application/json",
          "MS-Contract-Version": "1"
        }
        query = {
          setvar: "fltaad:1"
        }

        uri = URI("https://developer.microsoft.com/vsapi/applications")
        uri.query = URI.encode_www_form(query)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        request = Net::HTTP::Get.new(uri, headers)
        response = https.request(request)

        begin
          data = JSON.parse(response.body)

          if response.code == "200"
            UI.message("Application info was obtained")

            product = data["Products"].find { |x| x["LandingUrl"].include?(app_id) }
            return {
              identity: product["MainPackageIdentityName"],
              names: product["ReservedNames"]
            }
          end

          UI.user_error!("Request returned the error: #{response.code}")
        rescue StandardError => ex
          UI.user_error!("Application info request failed: #{ex}")
        end
      end

      def self.acquire_authorization_token
        UI.message("Acquiring authorization token ...")

        username = Actions.lane_context[SharedValues::SF_MS_USERNAME]
        password = Actions.lane_context[SharedValues::SF_MS_PASSWORD]
        tenant_id = Actions.lane_context[SharedValues::SF_MS_TENANT_ID]
        client_id = Actions.lane_context[SharedValues::SF_MS_CLIENT_ID]
        client_secret = Actions.lane_context[SharedValues::SF_MS_CLIENT_SECRET]

        body = {
          client_id: client_id,
          client_secret: client_secret,
          client_info: 1,
          grant_type: "password",
          scope: "https://management.azure.com/.default offline_access openid profile",
          username: username,
          password: password
        }
        headers = {
          "x-anchormailbox": "upn:#{username}",
          "x-client-sku": "fastlane-sapfire-plugin",
          "Accept": "application/json"
        }

        uri = URI("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token")
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(uri, headers)
        request_body = URI.encode_www_form(body)
        response = https.request(request, request_body)

        begin
          data = JSON.parse(response.body)

          if response.code == "200"
            UI.message("Authorization token was obtained")
            return data["access_token"]
          end

          error = data["error"]
          error_description = data["error_description"]

          UI.user_error!("Request returned the error.\nCode: #{error}.\nDescription: #{error_description}")
        rescue StandardError => ex
          UI.user_error!("Authorization failed: #{ex}")
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
              UI.user_error!("The provided path doesn't point to AppxManifest-file") unless
                File.exist?(File.expand_path(value)) && value.end_with?(".appxmanifest")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_id,
            description: "The Microsoft Store ID of an application",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("The Microsoft Store ID can't be empty") unless value && !value.empty?
            end
          )
        ]
      end

      def self.category
        :project
      end
    end
  end
end
