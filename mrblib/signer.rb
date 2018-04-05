# [Aws::Sigv4::Signer]
# These sourcedoces are based on here:
# https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sigv4/lib/aws-sigv4/signer.rb
# Copyright 2013. amazon web services, inc. all rights reserved.
# License: http://www.apache.org/licenses/LICENSE-2.0
#
module Aws
  module Sigv4
    class Signer
      attr_reader :service
      attr_reader :region
      attr_reader :credentials_provider
      attr_reader :unsigned_headers
      attr_reader :apply_checksum_header

      def initialize(options = {})
        @service = extract_service(options)
        @region = extract_region(options)
        @credentials_provider = extract_credentials_provider(options)
        @unsigned_headers = Set.new(options.fetch(:unsigned_headers, []).map(&:downcase))
        @unsigned_headers << 'authorization'
        @unsigned_headers << 'x-amzn-trace-id'
        %i[uri_escape_path apply_checksum_header].each do |opt|
          instance_variable_set("@#{opt}", options.key?(opt) ? !!options[:opt] : true)
        end
      end

      def sign_request(request)
        creds = get_credentials

        http_method = extract_http_method(request)
        url = extract_url(request)
        headers = downcase_headers(request[:headers])

        datetime = headers['x-amz-date']
        datetime ||= Time.now.utc.strftime('%Y%m%dT%H%M%SZ')
        date = datetime[0, 8]

        content_sha256 = headers['x-amz-content-sha256']
        content_sha256 ||= sha256_hexdigest(request[:body] || '')

        sigv4_headers = {}
        sigv4_headers['host'] = host(url)
        sigv4_headers['x-amz-date'] = datetime
        sigv4_headers['x-amz-security-token'] = creds.session_token if creds.session_token
        sigv4_headers['x-amz-content-sha256'] ||= content_sha256 if @apply_checksum_header

        headers = headers.merge(sigv4_headers) # merge so we do not modify given headers hash

        # compute signature parts
        creq = canonical_request(http_method, url, headers, content_sha256)
        sts = string_to_sign(datetime, creq)
        sig = signature(creds.secret_access_key, date, sts)

        # apply signature
        sigv4_headers['authorization'] = [
          "AWS4-HMAC-SHA256 Credential=#{credential(creds, date)}",
          "SignedHeaders=#{signed_headers(headers)}",
          "Signature=#{sig}"
        ].join(', ')

        # Returning the signature components.
        Signature.new(
          headers: sigv4_headers,
          string_to_sign: sts,
          canonical_request: creq,
          content_sha256: content_sha256
        )
      end

      def presign_url(options)
        creds = get_credentials

        http_method = extract_http_method(options)
        url = extract_url(options)

        headers = downcase_headers(options[:headers])
        headers['host'] = host(url)

        datetime = headers['x-amz-date']
        datetime ||= (options[:time] || Time.now).utc.strftime('%Y%m%dT%H%M%SZ')
        date = datetime[0, 8]

        content_sha256 = headers['x-amz-content-sha256']
        content_sha256 ||= options[:body_digest]
        content_sha256 ||= sha256_hexdigest(options[:body] || '')

        params = {}
        params['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256'
        params['X-Amz-Credential'] = credential(creds, date)
        params['X-Amz-Date'] = datetime
        params['X-Amz-Expires'] = extract_expires_in(options)
        params['X-Amz-SignedHeaders'] = signed_headers(headers)
        params['X-Amz-Security-Token'] = creds.session_token if creds.session_token

        params = params.map do |key, value|
          "#{uri_escape(key)}=#{uri_escape(value)}"
        end.join('&')

        if url.query
          url.query += '&' + params
        else
          url.query = params
        end

        creq = canonical_request(http_method, url, headers, content_sha256)
        sts = string_to_sign(datetime, creq)
        url.query += '&X-Amz-Signature=' + signature(creds.secret_access_key, date, sts)
        url
      end

      private

      def canonical_request(http_method, url, headers, content_sha256)
        [
          http_method,
          path(url),
          normalized_querystring(url.query || ''),
          canonical_headers(headers) + "\n",
          signed_headers(headers),
          content_sha256
        ].join("\n")
      end

      def string_to_sign(datetime, canonical_request)
        [
          'AWS4-HMAC-SHA256',
          datetime,
          credential_scope(datetime[0, 8]),
          sha256_hexdigest(canonical_request)
        ].join("\n")
      end

      def credential_scope(date)
        [
          date,
          @region,
          @service,
          'aws4_request'
        ].join('/')
      end

      def credential(credentials, date)
        "#{credentials.access_key_id}/#{credential_scope(date)}"
      end

      def signature(secret_access_key, date, string_to_sign)
        k_date = hmac('AWS4' + secret_access_key, date)
        k_region = hmac(k_date, @region)
        k_service = hmac(k_region, @service)
        k_credentials = hmac(k_service, 'aws4_request')
        hexhmac(k_credentials, string_to_sign)
      end

      def path(url)
        path = url.path
        path = '/' if path == ''
        if @uri_escape_path
          uri_escape_path(path)
        else
          path
        end
      end

      def normalized_querystring(querystring)
        params = querystring.split('&')
        params = params.map { |param| param =~ /=/ ? param : param + '=' }
        # We have to sort by param name and preserve order of params that
        # have the same name. Default sort <=> in JRuby will swap members
        # occasionally when <=> is 0 (considered still sorted), but this
        # causes our normalized query string to not match the sent querystring.
        # When names match, we then sort by their original order
        params = params.each_with_index.sort do |a, b|
          a, a_offset = a
          a_name = a.split('=')[0]
          b, b_offset = b
          b_name = b.split('=')[0]
          if a_name == b_name
            a_offset <=> b_offset
          else
            a_name <=> b_name
          end
        end.map(&:first).join('&')
      end

      def signed_headers(headers)
        headers.inject([]) do |signed_headers, header|
          header = header.shift
          if @unsigned_headers.include?(header)
            signed_headers
          else
            signed_headers << header
          end
        end.sort.join(';')
      end

      def canonical_headers(headers)
        headers = headers.inject([]) do |headers, header|
          k, v = header
          if @unsigned_headers.include?(k)
            headers
          else
            headers << [k, v]
          end
        end
        headers = headers.sort_by(&:first)
        headers.map { |k, v| "#{k}:#{canonical_header_value(v.to_s)}" }.join("\n")
      end

      def canonical_header_value(value)
        value =~ /^".*"$/ ? value : value.gsub(/\s+/, ' ').strip
      end

      def host(uri)
        if standard_port?(uri)
          uri.host
        else
          "#{uri.host}:#{uri.port}"
        end
      end

      def standard_port?(uri)
        (uri.scheme == 'http' && uri.port == 80) ||
          (uri.scheme == 'https' && uri.port == 443)
      end

      def sha256_hexdigest(value)
        if (File === value || Tempfile === value) && !value.path.nil? && File.exist?(value.path)
          Digest::SHA256.file(value.path).hexdigest
        elsif value.respond_to?(:read)
          sha256 = Digest::SHA256.new
          while chunk = value.read(1024 * 1024) # 1MB
            sha256.update(chunk)
          end
          value.rewind
          sha256.hexdigest
        else
          Digest::SHA256.hexdigest(value)
        end
      end

      def hmac(key, value)
        Digest::HMAC.digest(value, key, Digest::SHA256)
      end

      def hexhmac(key, value)
        Digest::HMAC.hexdigest(value, key, Digest::SHA256)
      end

      def extract_service(options)
        raise ArgumentError, 'missing required option :service' unless options[:service]
        options[:service]
      end

      def extract_region(options)
        raise Errors::MissingRegionError unless options[:region]
        options[:region]
      end

      def extract_credentials_provider(options)
        if options[:credentials_provider]
          options[:credentials_provider]
        elsif options.key?(:credentials) || options.key?(:access_key_id)
          StaticCredentialsProvider.new(options)
        else
          raise Errors::MissingCredentialsError
        end
      end

      def extract_http_method(request)
        raise ArgumentError, 'missing required option :http_method' unless request[:http_method]
        request[:http_method].upcase
      end

      def extract_url(request)
        raise ArgumentError, 'missing required option :url' unless request[:url]
        URI.parse(request[:url].to_s)
      end

      def downcase_headers(headers)
        (headers || {}).to_hash.each_with_object({}) do |obj, hash|
          key = obj.shift
          hash[key.downcase] = headers[key]
        end
      end

      def extract_expires_in(options)
        case options[:expires_in]
        when nil then 900.to_s
        when Integer then options[:expires_in].to_s
        else
          msg = 'expected :expires_in to be a number of seconds'
          raise ArgumentError, msg
        end
      end

      def uri_escape(string)
        self.class.uri_escape(string)
      end

      def uri_escape_path(string)
        self.class.uri_escape_path(string)
      end

      def get_credentials
        credentials = @credentials_provider.credentials
        if credentials_set?(credentials)
          credentials
        else
          raise Errors::MissingCredentialsError, 'unable to sign request without credentials set'
        end
      end

      def credentials_set?(credentials)
        credentials.access_key_id && credentials.secret_access_key
      end

      class << self
        def uri_escape_path(path)
          path.gsub(/[^\/]+/) { |part| uri_escape(part) }
        end

        def uri_escape(string)
          if string.nil?
            nil
          else
            URI.encode_www_form_component(string).gsub('+', '%20').gsub('%7E', '~')
          end
        end
      end
    end
  end
end
