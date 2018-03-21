# mruby-aws-sigv4 [![Build Status](https://travis-ci.org/hfm/mruby-aws-sigv4.svg?branch=master)](https://travis-ci.org/hfm/mruby-aws-sigv4)

[AWS Signature Version 4](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html) signing library for mruby. mruby port of [aws-sigv4 gem](https://rubygems.org/gems/aws-sigv4/).

## Install by mrbgems

- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

    # ... (snip) ...

    conf.gem :github => 'hfm/mruby-aws-sigv4'
end
```

## How to use Aws::Sigv4::Signer

Aws::Sigv4::Signer is a utility class for creating a signature of AWS Signature Version 4.

### Initialize

The signer requires `:service`, `:region`, and credentials for initialization. You can configure it with the following ways.

#### 1. Using static credentials

Static credentials is the most simple way to configure. You can set `:access_key_id` and `:secret_access_key`.

```ruby
signer = Aws::Sigv4::Signer.new(
  service: 's3',
  region: 'us-east-1',
  access_key_id: 'AKIDEXAMPLE',
  secret_access_key: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
)
```

#### 2. Using `:credentials` parametar

You can set [Credentials](./mrblib/credencials.rb) to `:credentials`.

```ruby
creds = Aws::Sigv4::Credentials.new(
  access_key_id: 'AKIDEXAMPLE',
  secret_access_key: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
)

signer = Aws::Sigv4::Signer.new(
  service: 's3',
  region: 'us-east-1',
  credentials: creds,
)
```

#### 3. Using `:credentials_provider` parametar:

`:credentials_provider` requires any object that has the following methods:

Method | Return object
---|---
`#access_key_id` | String
`#secret_access_key` | String
`#session_token` | String or nil

```ruby
creds_provider = Aws::Sigv4::StaticCredentialsProvider.new(
  access_key_id: 'akid',
  secret_access_key: 'secret',
)

signer = Aws::Sigv4::Signer.new(
  service: 's3',
  region: 'us-east-1',
  credentials_provider: creds_provider,
)
```

#### Other initialization parametars

option | default | description
---|---|---
`:session_token` | nil | The [X-Amz-Security-Token](https://docs.aws.amazon.com/STS/latest/APIReference/CommonParameters.html#CommonParameters-X-Amz-Security-Token).
`:unsigned_headers` | [] | A list of headers that should not be signed. This is useful when a proxy modifies headers, such as 'User-Agent', invalidating a signature.
`:uri_escape_path` | true | When `true`, the request URI path is uri-escaped as part of computing the canonical request string.
`:apply_checksum_header` | true | When `true`, the computed content checksum is returned in the hash of signature headers.

### Two methods for generating signatures

Aws::Sigv4::Signer class provides two methods for generating signatures:

- [`:sign_request`](#sign_request-method)
- [`:presign_url`](#presign_url-method)

#### `#sign_request` method

Computes a version 4 signature signature. Returns an instance of [Signature](./mrblib/signature.rb) which has `headers` hash to apply to your HTTP request.

##### Options

param | type | default | description
---|---|---|---
`:http_method` | String | - | One of 'GET', 'HEAD', 'PUT', 'POST', 'PATCH', or 'DELETE'
`:url` |  String, URI::HTTPS, URI::HTTP | - | The request URI. Must be a valid HTTP or HTTPS URI.
`:headers` | Hash | {} | This parametar is optional. A hash of headers to sign.
`:body` | String, IO | '' | This parametar is optional. The HTTP request body for computing a sha256 checksum. If the 'X-Amz-Content-Sha256' header is set to `:headers`, This param will not be read.

##### Examples

```ruby
# GET
signature = signer.sign_request(
  http_method: 'GET',
  url: 'http://domain.com',
)

# PUT
signature = signer.sign_request(
  http_method: 'PUT',
  url: 'http://domain.com',
  body: 'helloworld',
)
```

Apply the following hash of headers in Signature class to your HTTP request:

```ruby
signature.headers['authorization']
signature.headers['host']
signature.headers['x-amz-date']
signature.headers['x-amz-content-sha256']
signature.headers['x-amz-security-token']
```

#### `#presign_url` method

Signs a URL with query authentication. Using query parameters to authenticate requests is useful when you want to express a request entirely in a URL.

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
