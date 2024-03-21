module Fastlane
  module Helper
    class MsCredentials
      attr_writer :username, :password, :tenant_id, :client_id, :client_secret

      def username
        check_value("username", @username)
        @username
      end

      def password
        check_value("password", @password)
        @password
      end

      def tenant_id
        check_value("tenant_id", @tenant_id)
        @tenant_id
      end

      def client_id
        check_value("client_id", @client_id)
        @client_id
      end

      def client_secret
        check_value("client_secret", @client_secret)
        @client_secret
      end

      def check_value(name, value)
        raise "Microsoft credential variable hasn't been set: #{name}. You must call ms_credentials action before." if
          value.nil? || value.empty?
      end

      private(:check_value)
    end

    class << self
      attr_accessor :ms_credentials
    end

    self.ms_credentials = MsCredentials.new

    private_class_method(:ms_credentials=)
  end
end
