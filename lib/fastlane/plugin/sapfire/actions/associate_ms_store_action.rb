require "uri"
require "net/http"
require "json"
require "fastlane/action"

module Fastlane
  module Actions
    class AssociateMsStoreAction < Action
      @token = ""
      @vsapi_host = ""
      @vsapi_endpoint = ""

      XML_NAME = "Package.StoreAssociation.xml".freeze

      def self.run(params)
        FastlaneCore::PrintTable.print_values(config: params, title: "Summary for associate_ms_store")

        begin
          UI.message("Creating #{XML_NAME}...")

          acquire_authorization_token
          acquire_vsapi_location
          ms_developer_info = developer_info
          ms_app_info = app_info(params[:app_id])
          create_xml(params[:manifest], ms_developer_info, ms_app_info)

          UI.message("#{XML_NAME} successfully created")
        rescue StandardError => ex
          UI.user_error!("Something went wrong while associating the project: #{ex}")
        end
      end

      def self.create_xml(manifest_path, developer_info, app_info)
        appxmanifest_xml = get_appxmanifest_xml(manifest_path)

        UI.message("Set identity name: #{app_info.identity}")

        begin
          identity_entry = appxmanifest_xml.elements["Package"]
                                           .elements["Identity"]
          identity_entry.attributes["Name"] = app_info.identity
          identity_entry.attributes["Publisher"] = developer_info.publisher

          properties_entry = appxmanifest_xml.elements["Package"]
                                             .elements["Properties"]
          properties_entry.elements["DisplayName"].text = app_info.names[0] unless app_info.names.empty?
          properties_entry.elements["PublisherDisplayName"].text = developer_info.display_name
        rescue StandardError => ex
          UI.user_error!("Can't update app manifest: #{ex}")
        end

        save_xml(appxmanifest_xml, manifest_path)

        UI.message("Set publisher data: #{developer_info.publisher}")
        UI.message("Set publisher display name: #{developer_info.display_name}")

        document = REXML::Document.new
        document.xml_decl.version = "1.0"
        document.xml_decl.encoding = "utf-8"
        xmlns_args = {
          "xmlns" => "http://schemas.microsoft.com/appx/2010/storeassociation"
        }
        store_association = document.add_element("StoreAssociation", xmlns_args)
        store_association.add_element("Publisher").text = developer_info.publisher
        store_association.add_element("PublisherDisplayName").text = developer_info.display_name
        store_association.add_element("DeveloperAccountType").text = "WSA"
        store_association.add_element("GeneratePackageHash").text = "http://www.w3.org/2001/04/xmlenc#sha256"

        product_reserved_info = store_association.add_element("ProductReservedInfo")
        product_reserved_info.add_element("MainPackageIdentityName").text = app_info.identity

        reserved_names = product_reserved_info.add_element("ReservedNames")
        app_info.names.each do |x|
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

      def self.developer_info
        UI.message("Obtaining developer info ...")

        headers = {
          "Authorization": "Bearer #{@token}",
          "Accept": "application/json",
          "MS-Contract-Version": "1"
        }
        query = {
          setvar: "fltaad:1"
        }
        connection = Faraday.new(@vsapi_host)

        begin
          response = connection.get("#{@vsapi_endpoint}/developer", query, headers)

          if response.status == 200
            data = JSON.parse(response.body)
            developer_info = DeveloperInfo.new(data["PublisherDisplayName"], data["Publisher"])

            UI.message("Developer info was obtained")

            return developer_info
          end

          UI.user_error!("Request returned the error: #{response.status}")
        rescue StandardError => ex
          UI.user_error!("Developer info request failed: #{ex}")
        end
      end

      def self.app_info(app_id)
        UI.message("Obtaining application info ...")

        headers = {
          "Authorization": "Bearer #{@token}",
          "Accept": "application/json",
          "MS-Contract-Version": "1"
        }
        query = {
          setvar: "fltaad:1"
        }
        connection = Faraday.new(@vsapi_host)

        begin
          response = connection.get("#{@vsapi_endpoint}/applications", query, headers)

          if response.status == 200
            data = JSON.parse(response.body)
            product = data["Products"].find { |x| x["LandingUrl"].include?(app_id) }
            app_info = AppInfo.new(product["MainPackageIdentityName"], product["ReservedNames"])

            UI.message("Application info was obtained")

            return app_info
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
          scope: "https://graph.windows.net/.default offline_access openid profile",
          username: username,
          password: password
        }
        headers = {
          "x-anchormailbox": "upn:#{username}",
          "x-client-sku": "fastlane-sapfire-plugin",
          "Accept": "application/json"
        }
        connection = Faraday.new("https://login.microsoftonline.com")
        request_body = URI.encode_www_form(body)

        begin
          response = connection.post("/#{tenant_id}/oauth2/v2.0/token", request_body, headers)
          data = JSON.parse(response.body)

          if response.status == 200
            @token = data["access_token"]
            UI.message("Authorization token was obtained")

            return
          end

          error = data["error"]
          error_description = data["error_description"]

          UI.user_error!("Request returned the error.\nCode: #{error}.\nDescription: #{error_description}")
        rescue StandardError => ex
          UI.user_error!("Authorization failed: #{ex}")
        end
      end

      def self.acquire_vsapi_location
        query = {
          LinkId: "875315" # VS API constant
        }
        connection = Faraday.new("https://go.microsoft.com")

        begin
          response = connection.get("/fwlink", query)

          if response.status == 302
            raise "'Location' header isn't presented" unless response.headers.include?("Location")

            location = response.headers["Location"]
            uri = URI(location)
            @vsapi_host = "#{uri.scheme}://#{uri.host}"
            @vsapi_endpoint = uri.path

            UI.message("VS API endpoint: #{location}")

            return
          end

          UI.user_error!("Request returned the error: #{response.status}")
        rescue StandardError => ex
          UI.user_error!("Failed to get VS API endpoint location: #{ex}")
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

      def self.output
        [
          ["SF_PROJECT_MANIFEST", "Path to the APPX package manifest"],
          ["SF_APP_ID", "The Microsoft Store ID of an application"]
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :manifest,
            env_name: "SF_PROJECT_MANIFEST",
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
            env_name: "SF_APP_ID",
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

    class DeveloperInfo
      attr_reader :display_name, :publisher

      def initialize(display_name, publisher)
        @display_name = display_name
        @publisher = publisher
      end
    end

    class AppInfo
      attr_reader :identity, :names

      def initialize(identity, names)
        @identity = identity
        @names = names
      end
    end
  end
end
