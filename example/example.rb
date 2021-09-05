# frozen_string_literal: true

require File.absolute_path('../ztwrk', __dir__)

loader = ZTWRK.new(File.expand_path('lib', __dir__))
loader.setup

Foo.hello
Bar::Baz.say
