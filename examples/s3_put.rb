url = URI.parse 'https://<bucket>.s3-<region>.amazonaws.com/helloworld.txt'

message = 'helloworld'

signer = Aws::Sigv4::Signer.new(
  service: 's3',
  region: '<region>',
  access_key_id: 'AKIDEXAMPLE',
  secret_access_key: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
)

signature = signer.sign_request(
  http_method: 'PUT',
  url: url,
  body: message,
)

puts "uploading...\n\n"
# SimpleHttp is from https://github.com/matsumotory/mruby-simplehttp
http = SimpleHttp.new(url.scheme, url.host)
res = http.put(url.path, {
  'Host'                 => signature.headers['host'],
  'X-Amz-Date'           => signature.headers['x-amz-date'],
  'X-Amz-Content-Sha256' => signature.headers['x-amz-content-sha256'],
  'Authorization'        => signature.headers['authorization'],
  'Body'                 => message,
})
puts res.header

signature = signer.sign_request(
  http_method: 'GET',
  url: url,
)

puts "\n--- --- --- --- --- ---\n\ndownloading...\n\n"
res = http.get(url.path, {
  'Host'                 => signature.headers['host'],
  'X-Amz-Date'           => signature.headers['x-amz-date'],
  'X-Amz-Content-Sha256' => signature.headers['x-amz-content-sha256'],
  'Authorization'        => signature.headers['authorization'],
})
puts res.header
puts
puts res.body

__END__
$ mruby/bin/mruby examples/s3_put.rb
uploading...

HTTP/1.1 200 OK
x-amz-id-2: UG45045P2/v/6hg7YTETfY6yV5kV9iBLmZWpMcgTkfq9kYJ4uuXdyVYchhQVQhCG79S7jzOd3TI=
x-amz-request-id: 5379C9488FA30AA0
Date: Wed, 21 Mar 2018 19:06:22 GMT
ETag: "fc5e038d38a57032085441e7fe7010b0"
Content-Length: 0
Server: AmazonS3
Connection: close

--- --- --- --- --- ---

downloading...

HTTP/1.1 200 OK
x-amz-id-2: DWmXwyuWZCpnVHIeIf1NMbIpiAQ+jWobctGzEUEQd0U0eRfjIZDf6R1GpnxabBMvY1waO6AHmjs=
x-amz-request-id: 132ECD3D64B3603B
Date: Wed, 21 Mar 2018 19:06:22 GMT
Last-Modified: Wed, 21 Mar 2018 19:06:22 GMT
ETag: "fc5e038d38a57032085441e7fe7010b0"
Accept-Ranges: bytes
Content-Type: binary/octet-stream
Content-Length: 10
Server: AmazonS3
Connection: close

helloworld
