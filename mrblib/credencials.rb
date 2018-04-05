# [Aws::Sigv4::Credentials]
# These sourcedoces are based on here:
# https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sigv4/lib/aws-sigv4/credentials.rb
# Copyright 2013. amazon web services, inc. all rights reserved.
# License: http://www.apache.org/licenses/LICENSE-2.0
#
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
