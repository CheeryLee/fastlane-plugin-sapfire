module Fastlane
  module Helper
    class MsDevCenterHelper
      HOST = "https://manage.devcenter.microsoft.com".freeze
      API_VERSION = "v1.0".freeze
      API_ROOT = "my/applications".freeze
      REQUEST_HEADERS = {
        "Accept": "application/json"
      }.freeze

      def self.get_app_info(app_id, auth_token, timeout = 0)
        check_app_id(app_id)

        connection = Faraday.new(HOST)
        url = build_url_root(app_id)

        begin
          response = connection.get(url) do |req|
            req.headers = build_headers(auth_token)
            req.options.timeout = timeout if timeout.positive?
          end
          data = JSON.parse(response.body)

          return data if response.status == 200

          UI.user_error!("Getting app request returned the error.\nCode: #{response.status}")
        rescue StandardError => ex
          UI.user_error!("Getting app info process failed: #{ex}")
        end
      end

      def self.get_submission(app_id, flight_id, submission_id, auth_token, timeout = 0)
        check_app_id(app_id)
        check_submission_id(submission_id)

        is_flight = !flight_id.nil? && !flight_id.empty?
        check_flight_id(flight_id) if is_flight

        connection = Faraday.new(HOST)
        url = build_url_root(app_id)
        url += "/flights/#{flight_id}" if is_flight
        url += "/submissions/#{submission_id}"

        begin
          response = connection.get(url) do |req|
            req.headers = build_headers(auth_token)
            req.options.timeout = timeout if timeout.positive?
          end
          data = JSON.parse(response.body)

          return data if response.status == 200

          code = data["code"]
          message = data["message"]

          UI.user_error!("Getting flight submission request returned the error.\nCode: #{response.status} #{code}.\nDescription: #{message}")
        rescue StandardError => ex
          UI.user_error!("Getting flight submission process failed: #{ex}")
        end
      end

      def self.create_submission(app_id, auth_token, timeout = 0)
        check_app_id(app_id)

        connection = Faraday.new(HOST)
        url = "#{build_url_root(app_id)}/submissions"

        begin
          response = connection.post(url) do |req|
            req.headers = build_headers(auth_token)
            req.options.timeout = timeout if timeout.positive?
          end
          data = JSON.parse(response.body)

          return data if response.status == 201

          code = data["code"]
          message = data["message"]

          UI.user_error!("Creating submission request returned the error.\nCode: #{response.status} #{code}.\nDescription: #{message}")
        rescue StandardError => ex
          UI.user_error!("Creating submission process failed: #{ex}")
        end
      end

      def self.update_submission(app_id, submission_obj, auth_token, timeout = 0)
        check_app_id(app_id)
        UI.user_error!("Submission data object need to be provided") if submission_obj.nil?

        connection = Faraday.new(HOST)
        flight_id = submission_obj["flightId"]
        submission_id = submission_obj["id"]
        url = build_url_root(app_id)
        url += "/flights/#{flight_id}" if !flight_id.nil? && !flight_id.empty?
        url += "/submissions/#{submission_id}"

        begin
          response = connection.put(url) do |req|
            req.headers = build_headers(auth_token)
            req.body = submission_obj.to_json
            req.options.timeout = timeout if timeout.positive?
          end
          data = JSON.parse(response.body)

          return data if response.status == 200

          UI.user_error!("Updating submission request returned the error.\nCode: #{response.status}")
        rescue StandardError => ex
          UI.user_error!("Updating submission process failed: #{ex}")
        end
      end

      def self.commit_submission(app_id, flight_id, submission_id, auth_token, timeout = 0)
        check_app_id(app_id)
        check_submission_id(submission_id)

        is_flight = !flight_id.nil? && !flight_id.empty?
        check_flight_id(flight_id) if is_flight

        connection = Faraday.new(HOST)
        url = build_url_root(app_id)
        url += "/flights/#{flight_id}" if is_flight
        url += "/submissions/#{submission_id}/commit"

        begin
          response = connection.post(url) do |req|
            req.headers = build_headers(auth_token)
            req.options.timeout = timeout if timeout.positive?
          end

          UI.user_error!("Committing submission request returned the error.\nCode: #{response.status}") unless response.status == 202
        rescue StandardError => ex
          UI.user_error!("Committing submission process failed: #{ex}")
        end
      end

      def self.remove_submission(app_id, submission_id, auth_token, timeout = 0)
        check_app_id(app_id)
        check_submission_id(submission_id)

        connection = Faraday.new(HOST)
        url = "#{build_url_root(app_id)}/submissions/#{submission_id}"

        begin
          response = connection.delete(url) do |req|
            req.headers = build_headers(auth_token)
            req.options.timeout = timeout if timeout.positive?
          end

          UI.user_error!("Deleting submission request returned the error.\nCode: #{response.status}") unless response.status == 204
        rescue StandardError => ex
          UI.user_error!("Deleting submission process failed: #{ex}")
        end
      end

      def self.get_submission_status(app_id, flight_id, submission_id, auth_token, timeout = 0)
        check_app_id(app_id)
        check_flight_id(flight_id) if !flight_id.nil? && !flight_id.empty?
        check_submission_id(submission_id)

        response = get_submission_status_internal(app_id, flight_id, submission_id, auth_token, timeout)

        # Sometimes MS can return internal server error code (500) that is not directly related to uploading process.
        # Once it happens, retry 3 times until we'll get a success response.
        if response[:status] == 500
          server_error_500_retry_counter = 0

          until server_error_500_retry_counter < 2
            server_error_500_retry_counter += 1
            response = get_submission_status_internal(app_id, flight_id, submission_id, auth_token, timeout)
            break if response.nil? || response[:status] == 200
          end
        end

        return response[:data] if !response.nil? && response[:status] == 200

        UI.user_error!("Submission status obtaining request returned the error.\nCode: #{response[:status]}")
      end

      def self.get_submission_status_internal(app_id, flight_id, submission_id, auth_token, timeout = 0)
        connection = Faraday.new(HOST)
        url = build_url_root(app_id)
        url += "/flights/#{flight_id}/" if !flight_id.nil? && !flight_id.empty?
        url += "/submissions/#{submission_id}/status"

        begin
          response = connection.get(url) do |req|
            req.headers = build_headers(auth_token)
            req.options.timeout = timeout if timeout.positive?
          end

          UI.error("Submission status obtaining request returned the error.\nCode: #{response.status}") if response.status != 200
          data = response.status == 200 ? JSON.parse(response.body) : nil
          {
            "data": data,
            "status": response.status
          }
        rescue StandardError => ex
          UI.user_error!("Submission status obtaining process failed: #{ex}")
        end
      end

      def self.create_flight(app_id, friendly_name, group_ids, auth_token, timeout = 0)
        check_app_id(app_id)

        friendly_name = !friendly_name.nil? && !friendly_name.empty? ? friendly_name : "Fastlane Sapfire Flight"
        body = {
          friendlyName: friendly_name,
          groupIds: group_ids
        }
        connection = Faraday.new(HOST)
        url = "#{build_url_root(app_id)}/flights"

        begin
          response = connection.post(url) do |req|
            req.headers = build_headers(auth_token)
            req.body = body.to_json
            req.options.timeout = timeout if timeout.positive?
          end
          data = JSON.parse(response.body)

          return data if response.status == 201

          code = data["code"]
          message = data["message"]

          UI.user_error!("Creating flight request returned the error.\nCode: #{response.status} #{code}.\nDescription: #{message}")
        rescue StandardError => ex
          UI.user_error!("Creating flight process failed: #{ex}")
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

        begin
          response = connection.post("/#{tenant_id}/oauth2/token") do |req|
            req.headers = headers
            req.body = body
            req.options.timeout = timeout if timeout.positive?
          end
          data = JSON.parse(response.body)

          return data["access_token"] if response.status == 200

          error = data["error"]
          error_description = data["error_description"]

          UI.user_error!("Authorization request returned the error.\nCode: #{error}.\nDescription: #{error_description}")
        rescue StandardError => ex
          UI.user_error!("Authorization failed: #{ex}")
        end
      end

      def self.non_published_submission(app_id, auth_token, timeout = 0)
        check_app_id(app_id)
        app_info = get_app_info(app_id, auth_token, timeout)
        app_info["pendingApplicationSubmission"]
      end

      def self.build_url_root(app_id)
        "/#{API_VERSION}/#{API_ROOT}/#{app_id}"
      end

      def self.build_headers(auth_token)
        {
          "Authorization": "Bearer #{auth_token}",
          "Content-Type": "application/json"
        }.merge(REQUEST_HEADERS)
      end

      def self.check_app_id(id)
        UI.user_error!("App ID need to be provided") if !id.is_a?(String) || id.nil? || id.empty?
      end

      def self.check_submission_id(id)
        UI.user_error!("Submission ID need to be provided") if !id.is_a?(String) || id.nil? || id.empty?
      end

      def self.check_flight_id(id)
        UI.user_error!("Flight ID need to be provided") if !id.is_a?(String) || id.nil? || id.empty?
      end


      public_class_method(:get_app_info)
      public_class_method(:get_submission)
      public_class_method(:create_submission)
      public_class_method(:update_submission)
      public_class_method(:commit_submission)
      public_class_method(:remove_submission)
      public_class_method(:get_submission_status)
      public_class_method(:create_flight)
      public_class_method(:acquire_authorization_token)
      public_class_method(:non_published_submission)

      private_class_method(:build_url_root)
      private_class_method(:build_headers)
      private_class_method(:check_app_id)
      private_class_method(:check_submission_id)
      private_class_method(:check_flight_id)
      private_class_method(:get_submission_status_internal)

      private_constant(:HOST)
      private_constant(:API_VERSION)
      private_constant(:API_ROOT)
      private_constant(:REQUEST_HEADERS)
    end
  end
end
