module Aws
  module Sigv4
    class Signature
      attr_accessor :headers
      attr_accessor :canonical_request
      attr_accessor :string_to_sign
      attr_accessor :content_sha256

      def initialize(options)
        @headers           = options[:headers]
        @canonical_request = options[:canonical_request]
        @string_to_sign    = options[:string_to_sign]
        @content_sha256    = options[:content_sha256]
      end
    end
  end
end
