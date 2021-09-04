require 'bundler/setup'
require './ztwrk'

loader = ZTWRK.new('lib')
loader.setup

Foo.hello
Bar::Baz.say