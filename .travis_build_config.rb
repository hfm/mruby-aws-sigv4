MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'default'
  conf.enable_test

  conf.gem File.expand_path(File.dirname(__FILE__))
  conf.gem mgem: 'mruby-dir'
  conf.gem mgem: 'mruby-dir-glob'
  conf.gem mgem: 'mruby-io'
  conf.gem mgem: 'mruby-regexp-pcre'
end
