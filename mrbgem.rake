MRuby::Gem::Specification.new('mruby-aws-sigv4') do |spec|
  spec.license = 'MIT'
  spec.authors = 'Okumura Takahiro'
  spec.summary = 'AWS Signature Version 4 signing library for mruby'
  spec.version = '1.0.0'

  spec.add_dependency 'mruby-digest'
  spec.add_dependency 'mruby-enum-ext', core: 'mruby-enum-ext'
  spec.add_dependency 'mruby-io', core: 'mruby-io'
  spec.add_dependency 'mruby-set'
  spec.add_dependency 'mruby-stringio'
  spec.add_dependency 'mruby-time-strftime'
  spec.add_dependency 'mruby-uri', github: 'zzak/mruby-uri'

  spec.add_test_dependency 'mruby-dir'
  spec.add_test_dependency 'mruby-dir-glob'
  spec.add_test_dependency 'mruby-mtest'
  spec.add_test_dependency 'mruby-require', github: 'iij/mruby-require'
  spec.add_test_dependency 'mruby-symbol-ext', core: 'mruby-symbol-ext'
  spec.add_test_dependency 'mruby-tempfile'
end
