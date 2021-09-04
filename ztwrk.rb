require 'active_support/core_ext/string'

# How this should work:
#
# Give it a root directory
#   No registry, no exclusions, it just has one
# Call .setup to start discovery
# This iterates through the root tree with the following logic:
#   First get all ruby files
#   Call parent.autoload
#     Simple
#   Then get all directories
#     If the namespace doesn't exist yet (i.e. there's no explicit <namespace>.rb) autovivify it for the directory
#     Call the load function on the directory and recurse
#       It should be smart enough to get the right parent namespace if it's not Object
# No configurability, no error-checking.
class ZTWRK
  @@loader = false

  def self.loader
    @@loader
  end

  attr_reader :root_dir

  def initialize(root_dir)
    @root_dir = File.expand_path(root_dir)
    @@loader = self
  end

  def setup
    load_dir(root_dir)
  end

  def autovivify(path)
    namespace, element = constant_ref(relpath(path).camelize)
    namespace.const_set(element, Module.new)
  end

  private

  def load_dir(dir)
    # First load all Ruby files.
    # We have to do this first as these take precedence for creating namespaces.
    Dir.children(dir).filter { |p| /\.rb$/.match(p) }.each do |file|
      namespace, element = constant_ref(relpath(File.join(dir, file)).sub(/\.rb$/, '').camelize)
      namespace.autoload(element, File.join(dir, file))
    end

    # Then load all directories, and recurse into them.
    Dir.children(dir).filter { |subdir| File.directory?(File.join(dir, subdir)) }.each do |subdir|
      namespace, element = constant_ref(relpath(File.join(dir, subdir)).camelize)

      # See the Kernel patch and the autovivify method - this doesn't _actually_ load the subdir.
      namespace.autoload(element, File.join(dir, subdir)) unless namespace.const_defined?(element)
      load_dir(File.join(dir, subdir))
    end
  end

  def relpath(abspath)
    abspath.gsub(root_dir, '')[1..]
  end

  def constant_ref(camelized_path)
    path_parts = camelized_path.split('::')
    namespace = path_parts.size > 1 ? path_parts[0..-2].join('::').constantize : Object
    element = path_parts[-1].to_sym
    [namespace, element]
  end
end

module Kernel
  alias_method :original_require, :require

  def require(path)
    if ZTWRK.loader && path.start_with?(ZTWRK.loader.root_dir) && File.directory?(path)
      # Here we do what Zeitwerk calls 'autovivication' to fake the module.
      # Basically we stop it trying to load a directory (which is impossible) and instead fake the namespace with
      # a module.
      ZTWRK.loader.autovivify(path)
      return true
    end

    original_require(path)
  end
end
