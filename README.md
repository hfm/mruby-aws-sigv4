# mruby-aws-sigv4   [![Build Status](https://travis-ci.org/hfm/mruby-aws-sigv4.svg?branch=master)](https://travis-ci.org/hfm/mruby-aws-sigv4)
AwsSigv4 class
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
- see LICENSE file
