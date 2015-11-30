### START debundle.rb ###
module Debundle
  def self.debundle!
    if Gem.post_reset_hooks.reject!{ |hook| hook.source_location.first =~ %r{/bundler/} }
      Bundler.preserve_gem_path
      Gem.clear_paths
      warn_level = $VERBOSE
      $VERBOSE = nil
      load 'rubygems/core_ext/kernel_require.rb'
      load 'rubygems/core_ext/kernel_gem.rb'
      $VERBOSE = warn_level
    end
  rescue => e
    warn "DEBUNDLE.RB FAILED: #{e.class}\n#{e.message}"
  end
end
Debundle.debundle!
### END debundle.rb ###

require "awesome_print"
AwesomePrint.pry!

require "hirb"
extend Hirb::Console

def generate_tags
  require "bundler"
  require "pathname"
  current_path = Pathname.pwd
  relative_gem_paths = []
  Bundler.load.specs.each do |gem|
    relative_gem_paths << Pathname.new(gem.full_gem_path).relative_path_from(current_path)
  end
  %x(ctags -R --languages=ruby --exclude=.git --exclude=log . #{relative_gem_paths.join(" ")})
end
