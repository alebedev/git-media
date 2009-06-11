require 'trollop'
require 'git-media/clean'
require 'git-media/smudge'

module GitMedia
  
  def self.setup_media_buffer
    git_dir = `git rev-parse --git-dir`.chomp
    media_buffer = File.join(git_dir, 'media')
    Dir.mkdir(media_buffer) if !File.exist?(media_buffer)
    return media_buffer
  end
  
  module Application
    def self.run!
      
      cmd = ARGV.shift # get the subcommand
      cmd_opts = case cmd
        when "clean" # parse delete options
          GitMedia::Clean.run!
        when "smudge"
          GitMedia::Smudge.run!
        when 'status'
          Trollop::options do
            opt :force, "Force status"
          end
        else
          Trollop::die "unknown media subcommand #{cmd.inspect}"
        end
      
    end
  end
end
