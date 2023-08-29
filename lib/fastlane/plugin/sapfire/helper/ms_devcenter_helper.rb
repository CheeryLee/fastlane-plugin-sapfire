module Fastlane
  module Helper
    class MsDevCenterHelper
      HOST = "https://manage.devcenter.microsoft.com".freeze
      API_VERSION = "v1.0".freeze
      API_ROOT = "my/applications".freeze
      REQUEST_HEADERS = {
        "Accept": "application/json"
      }.freeze
      FILE_CHUNK_SIZE = 26_214_400
      UPLOAD_RETRIES = 3

      def self.upload_blob(url, zip_path, timeout = 0)
        UI.user_error!("File upload URL need to be provided") if !url.is_a?(String) || url.nil? || url.empty?
        UI.user_error!("File path is invalid") if !zip_path.is_a?(String) || zip_path.nil? || zip_path.empty?

        expand_path = File.expand_path(zip_path)
        UI.user_error!("The provided path doesn't point to ZIP file") unless File.exist?(expand_path) && zip_path.end_with?(".zip")

        File.open(expand_path) do |file|
          block_list = []
          chunks_count = (file.size.to_f / FILE_CHUNK_SIZE).ceil
          current_chunk = 1

          until file.eof?
            bytes = file.read(FILE_CHUNK_SIZE)
            id = SecureRandom.uuid.delete("-")
            block_list.append(id)
            retry_count = 0
            result = false

            UI.message("Upload chunk [#{current_chunk} / #{chunks_count}]")

            while !result && retry_count < UPLOAD_RETRIES
              result = upload_block(url, bytes, id, timeout)
              retry_count += 1
            end

            UI.user_error!("Uploading failed: some chunks have not been uploaded") unless result
            current_chunk += 1
          end

          result = upload_block_list(url, block_list, timeout)
          UI.user_error!("Uploading failed: block list hasn't been uploaded") unless result
        end
      end

      def self.upload_block(url, bytes, id, timeout = 0)
        headers = {
          "Content-Length": bytes.length.to_s
        }

        url_data = parse_upload_url(url)
        url_data[:query]["comp"] = "block"
        url_data[:query]["blockid"] = id

        connection = Faraday.new(url_data[:host])
        response = connection.put(url_data[:path]) do |req|
          req.headers = headers
          req.params = url_data[:query]
          req.body = bytes
          req.options.timeout = timeout if timeout.positive?
        end

        return true if response.status == 201

        error = response.body.to_s
        UI.error("Upload request failed.\nCode: #{response.status}\nError: #{error}")
        false
      end

      def self.upload_block_list(url, list, timeout = 0)
        document = REXML::Document.new
        document.xml_decl.version = "1.0"
        document.xml_decl.encoding = "utf-8"
        block_list = document.add_element("BlockList")

        list.each do |block|
          block_list.add_element("Latest").text = block
        end

        url_data = parse_upload_url(url)
        url_data[:query]["comp"] = "blocklist"

        connection = Faraday.new(url_data[:host])
        response = connection.put(url_data[:path]) do |req|
          req.params = url_data[:query]
          req.body = document.to_s
          req.options.timeout = timeout if timeout.positive?
        end

        return true if response.status == 201

        error = response.body.to_s
        UI.error("Upload block list request failed.\nCode: #{response.status}\nError: #{error}")
        false
      end

      def self.get_app_info(app_id, auth_token, timeout = 0)
        check_app_id(app_id)

        connection = Faraday.new(HOST)
        response = connection.get("/#{API_VERSION}/#{API_ROOT}/#{app_id}") do |req|
          req.headers = build_headers(auth_token)
          req.options.timeout = timeout if timeout.positive?
        end

        begin
          data = JSON.parse(response.body)
          return data if response.status == 200

          UI.user_error!("Request returned the error.\nCode: #{response.status}")
        rescue StandardError => ex
          UI.user_error!("Getting app info process failed: #{ex}")
        end
      end

      def self.create_submission(app_id, auth_token, timeout = 0)
        check_app_id(app_id)
        if non_published_submission?(app_id, auth_token, timeout)
          UI.user_error!([
            "There is a pending submission has already been created.",
            "You need to either proceed it or remove before creating a new one."
          ].join(" "))
        end

        connection = Faraday.new(HOST)
        response = connection.post("/#{API_VERSION}/#{API_ROOT}/#{app_id}/submissions") do |req|
          req.headers = build_headers(auth_token)
          req.options.timeout = timeout if timeout.positive?
        end

        begin
          data = JSON.parse(response.body)
          return data if response.status == 201

          code = data["code"]
          message = data["message"]

          UI.user_error!("Request returned the error.\nCode: #{response.status} #{code}.\nDescription: #{message}")
        rescue StandardError => ex
          UI.user_error!("Creating submission process failed: #{ex}")
        end
      end

      def self.update_submission(app_id, submission_obj, auth_token, timeout = 0)
        check_app_id(app_id)
        UI.user_error!("Submission data object need to be provided") if submission_obj.nil?

        submission_id = submission_obj["id"]
        connection = Faraday.new(HOST)
        response = connection.put("/#{API_VERSION}/#{API_ROOT}/#{app_id}/submissions/#{submission_id}") do |req|
          req.headers = build_headers(auth_token)
          req.body = submission_obj.to_json
          req.options.timeout = timeout if timeout.positive?
        end

        begin
          data = JSON.parse(response.body)
          return data if response.status == 200

          UI.user_error!("Request returned the error.\nCode: #{response.status}")
        rescue StandardError => ex
          UI.user_error!("Updating submission process failed: #{ex}")
        end
      end

      def self.commit_submission(app_id, submission_id, auth_token, timeout = 0)
        check_app_id(app_id)
        check_submission_id(submission_id)

        connection = Faraday.new(HOST)
        response = connection.post("/#{API_VERSION}/#{API_ROOT}/#{app_id}/submissions/#{submission_id}/commit") do |req|
          req.headers = build_headers(auth_token)
          req.options.timeout = timeout if timeout.positive?
        end

        UI.user_error!("Committing submission request returned the error.\nCode: #{response.status}") unless response.status == 202
      end

      def self.get_submission_status(app_id, submission_id, auth_token, timeout = 0)
        check_app_id(app_id)
        check_submission_id(submission_id)

        response = get_submission_status_internal(app_id, submission_id, auth_token, timeout)

        # Sometimes MS can return internal server error code (500) that is not directly related to uploading process.
        # Once it happens, retry 3 times until we'll get a success response.
        if response[:status] == 500
          server_error_500_retry_counter = 0

          until server_error_500_retry_counter < 2
            server_error_500_retry_counter += 1
            response = get_submission_status_internal(app_id, submission_id, auth_token, timeout)
            break if response.nil? || response[:status] == 200
          end
        end

        return response[:data] if !response.nil? && response[:status] == 200

        UI.user_error!("Submission status obtaining request returned the error.\nCode: #{response[:status]}")
      end

      def self.get_submission_status_internal(app_id, submission_id, auth_token, timeout = 0)
        connection = Faraday.new(HOST)
        response = connection.get("/#{API_VERSION}/#{API_ROOT}/#{app_id}/submissions/#{submission_id}/status") do |req|
          req.headers = build_headers(auth_token)
          req.options.timeout = timeout if timeout.positive?
        end

        begin
          UI.error("Request returned the error.\nCode: #{response.status}") if response.status != 200
          data = response.status == 200 ? JSON.parse(response.body) : nil
          {
            "data": data,
            "status": response.status
          }
        rescue StandardError => ex
          UI.user_error!("Submission status obtaining process failed: #{ex}")
          nil
        end
      end

      def self.acquire_authorization_token(tenant_id, client_id, client_secret, timeout = 0)
        body = {
          client_id: client_id,
          client_secret: client_secret,
          grant_type: "client_credentials",
          resource: HOST
        }
        headers = {
          "Content-Type": "application/x-www-form-urlencoded"
        }.merge(REQUEST_HEADERS)

        connection = Faraday.new("https://login.microsoftonline.com")
        response = connection.post("/#{tenant_id}/oauth2/token") do |req|
          req.headers = headers
          req.body = body
          req.options.timeout = timeout if timeout.positive?
        end

        begin
          data = JSON.parse(response.body)
          return data["access_token"] if response.status == 200

          error = data["error"]
          error_description = data["error_description"]

          UI.user_error!("Request returned the error.\nCode: #{error}.\nDescription: #{error_description}")
        rescue StandardError => ex
          UI.user_error!("Authorization failed: #{ex}")
        end
      end

      def self.non_published_submission?(app_id, auth_token, timeout = 0)
        check_app_id(app_id)
        app_info = get_app_info(app_id, auth_token, timeout)
        app_info.key?("pendingApplicationSubmission")
      end

      def self.build_headers(auth_token)
        {
          "Authorization": "Bearer #{auth_token}",
          "Content-Type": "application/json"
        }.merge(REQUEST_HEADERS)
      end

      def self.parse_upload_url(url)
        url = URI.parse(url)
        query_parts = {}
        url.query.split("&").each do |x|
          parts = x.split("=")
          query_parts[parts[0]] = CGI.unescape(parts[1])
        end

        {
          host: "https://#{url.host}",
          path: url.path,
          query: query_parts
        }
      end

      def self.check_app_id(id)
        UI.user_error!("App ID need to be provided") if !id.is_a?(String) || id.nil? || id.empty?
      end

      def self.check_submission_id(id)
        UI.user_error!("Submission ID need to be provided") if !id.is_a?(String) || id.nil? || id.empty?
      end

      public_class_method(:upload_blob)
      public_class_method(:get_app_info)
      public_class_method(:create_submission)
      public_class_method(:update_submission)
      public_class_method(:commit_submission)
      public_class_method(:get_submission_status)
      public_class_method(:acquire_authorization_token)

      private_class_method(:upload_block)
      private_class_method(:upload_block_list)
      private_class_method(:non_published_submission?)
      private_class_method(:build_headers)
      private_class_method(:parse_upload_url)
      private_class_method(:check_app_id)
      private_class_method(:check_submission_id)
      private_class_method(:get_submission_status_internal)

      private_constant(:HOST)
      private_constant(:API_VERSION)
      private_constant(:API_ROOT)
      private_constant(:REQUEST_HEADERS)
      private_constant(:FILE_CHUNK_SIZE)
      private_constant(:UPLOAD_RETRIES)
    end
  end
end
