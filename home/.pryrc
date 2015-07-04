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

`gem install awesome_print` unless defined? AwesomePrint
require "awesome_print"
AwesomePrint.pry!

`gem install hirb` unless defined? Hirb
require "hirb"
extend Hirb::Console
