# frozen_string_literal: true

require '../ztwrk'

loader = ZTWRK.new(File.expand_path('lib'))
loader.setup

Foo.hello
Bar::Baz.say
