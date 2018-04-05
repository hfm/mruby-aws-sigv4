# [Aws::Sigv4::Errors]
# These sourcedoces are based on here:
# https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sigv4/lib/aws-sigv4/errors.rb
# Copyright 2013. amazon web services, inc. all rights reserved.
# License: http://www.apache.org/licenses/LICENSE-2.0
#
module Aws
  module Sigv4
    module Errors
      class MissingCredentialsError < ArgumentError
        def initialize(msg = nil)
          super(msg || <<-MSG.strip)
missing credentials, provide credentials with one of the following options:
  - :access_key_id and :secret_access_key
  - :credentials
  - :credentials_provider
          MSG
        end
      end

      class MissingRegionError < ArgumentError
        def initialize(*_args)
          super('missing required option :region')
        end
      end
    end
  end
end
