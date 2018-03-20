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

## Usage of Aws::Sigv4::Signer

Aws::Sigv4::Signer is a utility class for creating a signature of AWS Signature Version 4. This class provides two methods for generating signatures:

- sign\_request
- presign\_url

### Initialize

The signer requires `:service`, `:region`, and credentials for initialization. You can configure it with the following ways.

#### Using static credentials

Static credentials is the most simple way to configure. You can set `:access_key_id` and `:secret_access_key`.

```ruby
signer = Aws::Sigv4::Signer.new(
  service: 's3',
  region: 'us-east-1',
  access_key_id: 'AKIDEXAMPLE',
  secret_access_key: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
)
```

#### Using `:credentials` parametar

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

#### Using `:credentials_provider` parametar:

The `:credentials_provider` requires any object that the following methods:

Method | Return object
---|---
`#access_key_id` | String
`#secret_access_key` | String
`#session_token` | String, nil

A credential provider is any object that responds to `#credentials`
returning another object that responds to `#access_key_id`, `#secret_access_key`,
and `#session_token`.

```ruby
signer = Aws::Sigv4::Signer.new(
  service: 's3',
  region: 'us-east-1',
  credentials_provider: Aws::Sigv4::StaticCredentialsProvider.new(
    access_key_id: 'akid',
    secret_access_key: 'secret',
  ),
)
```

#### Other parametars

option | default | description
---|---|---
`:session_token` | nil | [X-Amz-Security-Token header](https://docs.aws.amazon.com/STS/latest/APIReference/CommonParameters.html#CommonParameters-X-Amz-Security-Token).
`:unsigned_headers` | [] | A list of headers that should not be signed. This is useful when a proxy modifies headers, such as 'User-Agent', invalidating a signature.
`:uri_escape_path` | true | When `true`, the request URI path is uri-escaped as part of computing the canonical request string. This is required for every service, except Amazon S3, as of late 2016.
`:apply_checksum_header` | true | When `true`, the computed content checksum is returned in the hash of signature headers. This is required for AWS Glacier, and optional for every other AWS service as of late 2016.

Aws::Sigv4::Signer provides two methods for generating signatures:

- sign\_request
- presign\_url

### `#sign_request`

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

### `#presign_url`

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
