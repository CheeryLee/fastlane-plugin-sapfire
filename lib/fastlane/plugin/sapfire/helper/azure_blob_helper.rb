module Fastlane
  module Helper
    class AzureBlobHelper
      FILE_CHUNK_SIZE = 26_214_400
      UPLOAD_RETRIES = 3

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

        begin
          response = connection.put(url_data[:path]) do |req|
            req.headers = headers
            req.params = url_data[:query]
            req.body = bytes
            req.options.timeout = timeout if timeout.positive?
          end

          return true if response.status == 201

          error = response.body.to_s
          UI.error("Upload request failed.\nCode: #{response.status}\nError: #{error}")
        rescue StandardError => ex
          UI.error("Upload request failed: #{ex}")
        end

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

        begin
          response = connection.put(url_data[:path]) do |req|
            req.params = url_data[:query]
            req.body = document.to_s
            req.options.timeout = timeout if timeout.positive?
          end

          return true if response.status == 201

          error = response.body.to_s
          UI.error("Upload block list request failed.\nCode: #{response.status}\nError: #{error}")
        rescue StandardError => ex
          UI.error("Upload block list request failed: #{ex}")
        end

        false
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

      public_class_method(:create_blob_zip)
      public_class_method(:upload_blob)

      private_class_method(:upload_block)
      private_class_method(:upload_block_list)
      private_class_method(:parse_upload_url)

      private_constant(:FILE_CHUNK_SIZE)
      private_constant(:UPLOAD_RETRIES)
    end
  end
end
