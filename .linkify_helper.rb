require 'fileutils'
require 'pathname'

def home_directory *path
  path.empty? ?  ENV['HOME'] : File.join( ENV['HOME'], *path )
end

def dotfiles_directory *path
  path.empty? ?  File.dirname(__FILE__) : File.join( File.dirname(__FILE__), *path )
end

def ln source_path, target_path
  FileUtils.ln_s source_path, target_path, force: true
end


# Recursively link files from source to target directory
def linkify source_path, target_path
  Dir.glob( File.join(source_path, '*'), File::FNM_DOTMATCH ).each do |src_fn_path|
    src_pn = Pathname.new src_fn_path
    next if %w(. ..).include? src_pn.basename.to_s
    if src_pn.directory?
      FileUtils.mkdir_p File.join(target_path, src_pn.basename)
      linkify File.join(source_path, src_pn.basename), File.join(target_path, src_pn.basename)
    else
      ln src_pn, File.join(target_path, src_pn.basename)
    end
  end
end
