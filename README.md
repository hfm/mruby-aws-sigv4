# mruby-aws-sigv4   [![Build Status](https://travis-ci.org/hfm/mruby-aws-sigv4.svg?branch=master)](https://travis-ci.org/hfm/mruby-aws-sigv4)

AWS Signature Version 4 signing library for mruby. mruby port of [aws-sigv4 gem](https://rubygems.org/gems/aws-sigv4/).

## install by mrbgems

- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

    # ... (snip) ...

    conf.gem :github => 'hfm/mruby-aws-sigv4'
end
```
## example
```ruby
p AwsSigv4.hi
#=> "hi!!"
t = AwsSigv4.new "hello"
p t.hello
#=> "hello"
p t.bye
#=> "hello bye"
```

## License

under the MIT License:
- see [LICENSE](./LICENSE) file
