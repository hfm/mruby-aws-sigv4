# [Aws::Sigv4::SignerTest]
# These sourcedoces are based on here:
# https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sigv4/spec/signer_spec.rb
# Copyright 2013. amazon web services, inc. all rights reserved.
# License: http://www.apache.org/licenses/LICENSE-2.0
#
module Aws::Sigv4::SignerTest
  class ErrorsTest < MTest::Unit::TestCase
    def setup
      @credentials = { access_key_id: 'akid', secret_access_key: 'secret' }
      @options = {
        service: 'SERVICE',
        region: 'REGION',
        credentials_provider: Aws::Sigv4::StaticCredentialsProvider.new(@credentials)
      }
    end

    def test_service
      assert_raise ArgumentError do
        Aws::Sigv4::Signer.new(region: 'us-east-1', access_key_id: 'akid', secret_access_key: 'secret')
      end

      assert_equal @options[:service], Aws::Sigv4::Signer.new(@options).service
    end

    def test_region
      assert_raise Aws::Sigv4::Errors::MissingRegionError do
        Aws::Sigv4::Signer.new(service: 'ec2', access_key_id: 'akid', secret_access_key: 'secret')
      end

      assert_equal @options[:region], Aws::Sigv4::Signer.new(@options).region
    end
  end

  class CredentialsTest < MTest::Unit::TestCase
    def setup
      @credentials = { access_key_id: 'akid', secret_access_key: 'secret' }
      @options = { service: 'ec2', region: 'us-east-1' }
    end

    def test_credentials_error
      assert_raise(Aws::Sigv4::Errors::MissingCredentialsError) { Aws::Sigv4::Signer.new(@options) }
    end

    def test_credentials_without_a_session_token
      signer = Aws::Sigv4::Signer.new(@options.merge(
        access_key_id: 'akid',
        secret_access_key: 'secret'
      ))
      creds = signer.credentials_provider.credentials
      assert_equal 'akid', creds.access_key_id
      assert_equal 'secret', creds.secret_access_key
      assert_nil creds.session_token
    end

    def test_credentials_accepts_credentials_with_a_session_token
      signer = Aws::Sigv4::Signer.new(@options.merge(
        access_key_id: 'akid',
        secret_access_key: 'secret',
        session_token: 'token'
      ))
      creds = signer.credentials_provider.credentials
      assert_equal 'akid', creds.access_key_id
      assert_equal 'secret', creds.secret_access_key
      assert_equal 'token', creds.session_token
    end

    def test_credentials_accepts_credentials
      signer = Aws::Sigv4::Signer.new(@options.merge(
        credentials: Aws::Sigv4::Credentials.new(
          access_key_id: 'akid',
          secret_access_key: 'secret',
          session_token: 'token'
        )
      ))
      creds = signer.credentials_provider.credentials
      assert_equal 'akid', creds.access_key_id
      assert_equal 'secret', creds.secret_access_key
      assert_equal 'token', creds.session_token
    end

    def test_credentials_accepts_credentials_provider
      signer = Aws::Sigv4::Signer.new(@options.merge(
        credentials_provider: Aws::Sigv4::StaticCredentialsProvider.new(
          access_key_id: 'akid',
          secret_access_key: 'secret',
          session_token: 'token'
        )
      ))
      creds = signer.credentials_provider.credentials
      assert_equal 'akid', creds.access_key_id
      assert_equal 'secret', creds.secret_access_key
      assert_equal 'token', creds.session_token
    end
  end

  class CanonicalRequestTest < MTest::Unit::TestCase
    def setup
      @credentials = { access_key_id: 'akid', secret_access_key: 'secret' }
      @options = {
        service: 'SERVICE',
        region: 'REGION',
        credentials_provider: Aws::Sigv4::StaticCredentialsProvider.new(@credentials)
      }
    end

    def test_lower_cases_and_sort_all_header_keys_except_authorization
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com',
        headers: {
          'Xyz' => '1',
          'Abc' => '2',
          'Mno' => '3',
          'Authorization' => '4',
          'authorization' => '5',
          'X-Amz-Date' => '20161024T184027Z'
        }
      )
      assert_equal((<<-EOF.strip), signature.canonical_request)
PUT
/

abc:2
host:domain.com
mno:3
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20161024T184027Z
xyz:1

abc;host;mno;x-amz-content-sha256;x-amz-date;xyz
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    EOF
    end

    def test_ignore_configured_headers
      @options[:unsigned_headers] = ['cache-control', 'User-Agent'] # case insenstive
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com',
        headers: {
          'Abc' => '2',
          'Cache-Control' => '4',
          'User-Agent' => '5',
          'X-Amz-Date' => '20161024T184027Z'
        }
      )
      assert_equal((<<-EOF.strip), signature.canonical_request)
PUT
/

abc:2
host:domain.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20161024T184027Z

abc;host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    EOF
    end

    def test_lower_cases_and_sorts_header_by_key_except_authorization
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com',
        headers: {
          'Abc' => '1',
          'Mno' => '2',
          'Xyz' => '3',
          'Authorization' => '4',
          'authorization' => '5',
          'X-Amz-Date' => '20160101T112233Z'
        },
        body: ''
      )
      assert_equal((<<-EOF.strip), signature.canonical_request)
PUT
/

abc:1
host:domain.com
mno:2
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20160101T112233Z
xyz:3

abc;host;mno;x-amz-content-sha256;x-amz-date;xyz
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    EOF
    end

    def test_prunes_expanded_whitespace_in_header_values
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com',
        headers: {
          'Abc' => 'a  b  c', # double spaces between letters
          'X-Amz-Date' => '20160101T112233Z'
        },
        # defaults body to the empty string
      )
      assert_equal((<<-EOF.strip), signature.canonical_request)
PUT
/

abc:a b c
host:domain.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20160101T112233Z

abc;host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    EOF
    end

    def test_lower_cases_and_sort_header_by_key_except_authorization
      # it 'leaves whitespace in quoted values in-tact' do
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com',
        headers: {
          'Abc' => '"a  b  c"', # quoted header values preserve spaces
          'X-Amz-Date' => '20160101T112233Z'
        }
      )
      assert_equal((<<-EOF.strip), signature.canonical_request)
PUT
/

abc:"a  b  c"
host:domain.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20160101T112233Z

abc;host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    EOF
    end

    def test_normalize_valueless_querystring_keys_with_a_trailing_equal
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com?other=&test&x-amz-header=foo',
        headers: {
          'X-Amz-Date' => '20160101T112233Z'
        }
      )
      assert_equal((<<-EOF.strip), signature.canonical_request)
PUT
/
other=&test=&x-amz-header=foo
host:domain.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20160101T112233Z

host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    EOF
    end

    def test_sort_query_parameters
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com?foo=&bar=&baz=',
        headers: {
          'X-Amz-Date' => '20160101T112233Z'
        }
      )
      assert_equal((<<-EOF.strip), signature.canonical_request)
PUT
/
bar=&baz=&foo=
host:domain.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20160101T112233Z

host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    EOF
    end

    def test_sort_by_name_params_with_same_name_stay_in_the_same_order
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com?q.options=abc&q=xyz&q=mno',
        headers: {
          'X-Amz-Date' => '20160101T112233Z'
        }
      )
      assert_equal((<<-EOF.strip), signature.canonical_request)
PUT
/
q=xyz&q=mno&q.options=abc
host:domain.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20160101T112233Z

host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    EOF
    end

    def test_x_amz_content_sha256_header
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com',
        headers: {
          'X-Amz-Date' => '20160101T112233Z',
          'X-Amz-Content-Sha256' => 'CHECKSUM'
        }
      )
      assert_equal((<<-EOF.strip), signature.canonical_request)
PUT
/

host:domain.com
x-amz-content-sha256:CHECKSUM
x-amz-date:20160101T112233Z

host;x-amz-content-sha256;x-amz-date
CHECKSUM
    EOF
    end
  end

  class SignRequestTest < MTest::Unit::TestCase
    def setup
      @credentials = { access_key_id: 'akid', secret_access_key: 'secret' }
      @options = {
        service: 'SERVICE',
        region: 'REGION',
        credentials_provider: Aws::Sigv4::StaticCredentialsProvider.new(@credentials)
      }
    end

    def test_host_header
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'GET',
        url: 'http://domain.com'
      )
      assert_equal 'domain.com', signature.headers['host']
    end

    def test_http_port_not_80
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'GET',
        url: 'http://domain.com:123'
      )
      assert_equal 'domain.com:123', signature.headers['host']
    end

    def test_https_port_not_443
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'GET',
        url: 'https://domain.com:123'
      )
      assert_equal 'domain.com:123', signature.headers['host']
    end

    def test_x_amz_date_header
      now = Time.now
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'GET',
        url: 'https://domain.com:123'
      )
      assert_equal now.utc.strftime("%Y%m%dT%H%M%SZ"), signature.headers['x-amz-date']
    end

    def test_x_amz_date_header_in_request
      now = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'GET',
        url: 'https://domain.com',
        headers: {
          'X-Amz-Date' => now
        }
      )
      assert_equal now, signature.headers['x-amz-date']
    end

    def test_x_amz_security_token_header_with_session_token
      @credentials[:session_token] = 'token'
      @options = {
        service: 'SERVICE',
        region: 'REGION',
        credentials_provider: Aws::Sigv4::StaticCredentialsProvider.new(@credentials)
      }
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'GET',
        url: 'https://domain.com'
      )
      assert_equal 'token', signature.headers['x-amz-security-token']
    end

    def test_x_amz_security_token_header_without_session_token
      @credentials.delete(:session_token)
      @options = {
        service: 'SERVICE',
        region: 'REGION',
        credentials_provider: Aws::Sigv4::StaticCredentialsProvider.new(@credentials)
      }
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'GET',
        url: 'https://domain.com'
      )
      assert_nil signature.headers['x-amz-security-token']
    end

    def test_x_amz_content_sha256_header
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'GET',
        url: 'https://domain.com',
        body: 'abc'
      )
      assert_equal Digest::SHA256.hexdigest('abc'), signature.headers['x-amz-content-sha256']
    end

    def test_x_amz_content_sha256_header_when_apply_checksum_header_false
      @options[:apply_checksum_header] = false
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'GET',
        url: 'https://domain.com',
        body: 'abc'
      )
      assert_nil signature.headers['x-amz-content-sha256']
    end

    def test_checksum_files_without_loading_them_into_memory
      body = Tempfile.new('tempfile')
      body.write('abc')
      body.flush
      # expect(body).not_to receive(:read)
      # expect(body).not_to receive(:rewind)
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'POST',
        url: 'https://domain.com',
        body: body
      )
      assert_equal Digest::SHA256.hexdigest('abc'), signature.headers['x-amz-content-sha256']
    end

    def test_reads_non_file_IO_objects_into_memory_to_compute_checksusm
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com',
        body: StringIO.new('abc')
      )
      assert_equal Digest::SHA256.hexdigest('abc'), signature.headers['x-amz-content-sha256']
    end

    def test_not_read_body_if_x_amz_content_sha256_already_present
      body = 'http-payload'
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com',
        headers: {
          'X-Amz-Content-Sha256' => 'hexdigest'
        },
        body: body
      )
      assert_equal 'hexdigest', signature.headers['x-amz-content-sha256']
    end

    def test_authorization_header
      headers = {}
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'http://domain.com',
        headers: headers
      )
      # applied to the signature headers, not the request
      assert_nil headers['authorization']
      assert_false signature.headers['authorization'].nil?
    end

    def test_sign_request
      @options[:unsigned_headers] = ['content-length']
      signature = Aws::Sigv4::Signer.new(@options).sign_request(
        http_method: 'PUT',
        url: 'https://domain.com',
        headers: {
          'Foo' => 'foo',
          'Bar' => 'bar  bar',
          'Bar2' => '"bar  bar"',
          'Content-Length' => 9,
          'X-Amz-Date' => '20120101T112233Z',
        },
        body: StringIO.new('http-body')
      )
      assert_equal 'AWS4-HMAC-SHA256 Credential=akid/20120101/REGION/SERVICE/aws4_request, SignedHeaders=bar;bar2;foo;host;x-amz-content-sha256;x-amz-date, Signature=4a7d3e06d1950eb64a3daa1becaa8ba030d9099858516cb2fa4533fab4e8937d', signature.headers['authorization']
    end
  end
end

MTest::Unit.new.run
