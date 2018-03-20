# mruby-aws-sigv4   [![Build Status](https://travis-ci.org/hfm/mruby-aws-sigv4.svg?branch=master)](https://travis-ci.org/hfm/mruby-aws-sigv4)

[AWS Signature Version 4](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html) signing library for mruby. mruby port of [aws-sigv4 gem](https://rubygems.org/gems/aws-sigv4/).

## Install by mrbgems

- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

    # ... (snip) ...

    conf.gem :github => 'hfm/mruby-aws-sigv4'
end
```

## Usage

Aws::Sigv4::Signer, which is a utility class for creating the signature of AWS Signature Version 4, provides two methods for generating signatures:

- sign\_request
- presign\_url

### Using static credentials

```ruby
signer = Aws::Sigv4::Signer.new(
  service: 's3',
  region: 'us-east-1',
  access_key_id: 'akid',
  secret_access_key: 'secret',
)
```

### Using :credentials

```ruby
signer = Aws::Sigv4::Signer.new(
  service: 's3',
  region: 'us-east-1',
  credentials: Aws::Sigv4::Credentials.new(
    access_key_id: 'AKIDEXAMPLE',
    secret_access_key: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY'
  ),
)
```

### Using :credentials_provider

```ruby
signer = Aws::Sigv4::Signer.new(
  service: 's3',
  region: 'us-east-1',
  credentials_provider: Aws::Sigv4::StaticCredentialsProvider.new(
    access_key_id: 'akid',
    secret_access_key: 'secret',
    session_token: 'token'
  ),
)
```

#### Other parametars

option | default value | description
---|---|---
:unsigned\_headers | [] | A list of headers that should not be signed. This is useful when a proxy modifies headers, such as 'User-Agent', invalidating a signature.
:uri\_escape\_path | true | When `true`, the request URI path is uri-escaped as part of computing the canonical request string. This is required for every service, except Amazon S3, as of late 2016.
:apply\_checksum\_header | true | When `true`, the computed content checksum is returned in the hash of signature headers. This is required for AWS Glacier, and optional for every other AWS service as of late 2016.

### Aws::Sigv4::Signer#sign\_request

#### GET

```ruby
signature = signer.sign_request(
  http_method: 'GET',
  url: 'http://domain.com',
)
```

#### PUT

```ruby
signature = signer.sign_request(
  http_method: 'PUT',
  url: 'http://domain.com',
)
```

### Aws::Sigv4::Signer#presign\_url

```ruby
url = signer.presigned_url(
  http_method: 'PUT',
  url: 'https://my-bucket.s3-us-east-1.amazonaws.com/key',
  headers: {
    'X-Amz-Meta-Custom' => 'metadata'
  },
)
```

## License

under the MIT License:
- see [LICENSE](./LICENSE) file
