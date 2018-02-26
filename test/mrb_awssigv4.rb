##
## AwsSigv4 Test
##

assert("AwsSigv4#hello") do
  t = AwsSigv4.new "hello"
  assert_equal("hello", t.hello)
end

assert("AwsSigv4#bye") do
  t = AwsSigv4.new "hello"
  assert_equal("hello bye", t.bye)
end

assert("AwsSigv4.hi") do
  assert_equal("hi!!", AwsSigv4.hi)
end
