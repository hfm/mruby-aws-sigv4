module Aws
  module Sigv4
    class Credentials
      attr_reader :access_key_id
      attr_reader :secret_access_key
      attr_reader :session_token

      def initialize(options = {})
        unless options[:access_key_id] && options[:secret_access_key]
          raise ArgumentError, 'expected both :access_key_id and :secret_access_key options'
        end

        @access_key_id     = options[:access_key_id]
        @secret_access_key = options[:secret_access_key]
        @session_token     = options[:session_token]
      end
    end

    class StaticCredentialsProvider
      attr_reader :credentials

      def initialize(options = {})
        @credentials = options[:credentials] || Credentials.new(options)
      end
    end
  end
end
