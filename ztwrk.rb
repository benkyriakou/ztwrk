require 'active_support/core_ext/string'

class ZTWRK
  @@loader = nil

  def self.loader
    @@loader
  end

  attr_accessor :registry

  def initialize
    @registry = {}
    @@loader = self
  end

  def setup
    registry.each do |abspath, camelized_path|
      namespace, element = constant_ref(camelized_path)
      namespace.autoload(element, abspath)
    end
  end

  def constant_ref(camelized_path)
    path_parts = camelized_path.split('::')
    namespace = path_parts.size > 1 ? path_parts[0..-2].join('::').constantize : Object
    element = path_parts[-1].to_sym
    [namespace, element]
  end

  # This will only work for .rb files - anything else will be ignored.
  def register(*paths)
    paths.filter { |p| File.extname(p) == '.rb' }.each do |path|
      registry[File.expand_path(path)] = path.sub(/\.rb$/, '').camelize
    end
  end

  # Callback when the Kernel requires a file.
  def onload(path)
    namespace, element = constant_ref(registry[path])

    raise StandardError("Expected #{path} to define #{path.camelize}") unless namespace.const_defined?(element)
  end
end

module Kernel
  alias_method :original_require, :require

  def require(path)
    if ZTWRK.loader&.registry.key?(path)
      original_require(path).tap do |required|
        ZTWRK.loader&.onload(path) if required
      end
    else
      original_require(path)
    end
  end
end