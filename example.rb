# frozen_string_literal: true

require './ztwrk'

loader = ZTWRK.new('lib')
loader.setup

Foo.hello
Bar::Baz.say
