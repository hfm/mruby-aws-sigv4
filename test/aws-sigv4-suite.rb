require File.join(File.expand_path('..', __FILE__), 'test_helper.rb')

class Aws::Sigv4::SignerTestSuite < MTest::Unit::TestCase
  def setup
    @signer = Aws::Sigv4::Signer.new(
      service: 'service',
      region: 'us-east-1',
      credentials: Aws::Sigv4::Credentials.new(
        access_key_id: 'AKIDEXAMPLE',
        secret_access_key: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY'
      ),
      # necessary to pass the test suite
      uri_escape_path: false,
      apply_checksum_header: false
    )
  end

  def test_signer_suite
    Dir.glob(File.expand_path('../aws-sigv4-suite/**', __FILE__)).each do |path|
      prefix = File.join(path, File.basename(path))
      next unless File.exist?("#{prefix}.req")

      raw_request = File.read("#{prefix}.req", encoding: 'utf-8')
      request = TestHelper.parse_request(raw_request)
      signature = @signer.sign_request(request)

      expected_creq = File.read("#{prefix}.creq", encoding: 'utf-8')
      expected_sts = File.read("#{prefix}.sts", encoding: 'utf-8')
      expected_authz = File.read("#{prefix}.authz", encoding: 'utf-8')

      assert_equal expected_creq, signature.canonical_request
      assert_equal expected_sts, signature.string_to_sign
      assert_equal expected_authz, signature.headers['authorization']
    end
  end
end

MTest::Unit.new.run
