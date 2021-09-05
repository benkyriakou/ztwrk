# frozen_string_literal: true

# How this should work:
#
# Give it a root directory
#   No registry, no exclusions, it just has one
# Call .setup to start discovery
# This iterates through the root tree with the following logic:
#   First get all ruby files
#     Call parent.autoload
#       Simple
#   Then get all directories
#     If the namespace doesn't exist yet (i.e. there's no explicit <namespace>.rb) autovivify it for the directory
#     Call the load function on the directory and recurse
#       It should be smart enough to get the right parent namespace if it's not Object
# No configurability, no error-checking
class ZTWRK
  @@loader = nil

  def self.loader
    @@loader
  end

  attr_reader :root_dir

  def initialize(root_dir)
    @root_dir = root_dir
    @@loader = self
  end

  def setup
    load_dir(root_dir)
  end

  def autovivify(abspath)
    namespace, element = constant_ref(camelize(relpath(abspath)))
    namespace.const_set(element, Module.new)
  end

  def can_load?(abspath)
    abspath.start_with?(root_dir)
  end

  private

  def load_dir(dir)
    # First load all Ruby files.
    # We have to do this first as these take precedence for creating namespaces.
    ruby_files(dir).each do |relpath, abspath|
      namespace, element = constant_ref(camelize(relpath.sub(/\.rb$/, '')))
      namespace.autoload(element, abspath)
    end

    # Then load all directories, and recurse into them.
    subdirectories(dir).each do |relpath, abspath|
      namespace, element = constant_ref(camelize(relpath))

      # See the Kernel patch and the autovivify method - this doesn't _actually_ load the subdir.
      namespace.autoload(element, abspath) unless namespace.const_defined?(element)
      load_dir(abspath)
    end
  end

  def ruby_files(dir)
    Dir.children(dir)
       .map { |file| File.join(dir, file) }
       .filter { |abspath| File.extname(abspath) == '.rb' }
       .map { |abspath| [relpath(abspath), abspath] }
  end

  def subdirectories(dir)
    Dir.children(dir)
       .map { |subdir| File.join(dir, subdir) }
       .filter { |abspath| File.directory?(abspath) }
       .map { |abspath| [relpath(abspath), abspath] }
  end

  def relpath(abspath)
    abspath.gsub(%r{^#{root_dir}/}, '')
  end

  def constant_ref(camelized_path)
    path_parts = camelized_path.split('::')
    element = path_parts.pop.to_sym
    namespace = path_parts.empty? ? Object : Object.const_get(path_parts.join('::'))
    [namespace, element]
  end

  def camelize(path)
    path
      .split('/')
      .map { |part| part.split('_').map(&:capitalize).join }
      .join('::')
  end
end

module Kernel
  alias_method :original_require, :require

  def require(abspath)
    if ZTWRK.loader&.can_load?(abspath) && File.directory?(abspath)
      # Here we do what Zeitwerk calls 'autovivication' to fake the module.
      # Basically we stop it trying to load a directory (which is impossible) and instead create the namespace with
      # an empty module.
      ZTWRK.loader.autovivify(abspath)
      return true
    end

    original_require(abspath)
  end
end
