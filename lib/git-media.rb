require 'trollop'
require 'fileutils'
require 'git-media/transport/local'
require 'git-media/transport/s3'

module GitMedia

  def self.get_media_buffer
    @@git_dir ||= `git rev-parse --git-dir`.chomp
    media_buffer = File.join(@@git_dir, 'media/objects')
    FileUtils.mkdir_p(media_buffer) if !File.exist?(media_buffer)
    return media_buffer
  end

  def self.media_path(sha)
    buf = self.get_media_buffer
    File.join(buf, sha)    
  end
  
  # TODO: select the proper transports based on settings
  def self.get_push_transport
    #GitMedia::Transport::Local.new('/opt/media')
    #GitMedia::Transport::S3.new('chaconmedia', ACCESS_KEY, SECRET_KEY)
  end

  def self.get_pull_transport
    #GitMedia::Transport::S3.new('chaconmedia', ACCESS_KEY, SECRET_KEY)
  end

  module Application
    def self.run!
      
      cmd = ARGV.shift # get the subcommand
      cmd_opts = case cmd
        when "filter-clean" # parse delete options
          require 'git-media/filter-clean'
          GitMedia::FilterClean.run!
        when "filter-smudge"
          require 'git-media/filter-smudge'
          GitMedia::FilterSmudge.run!
        when "clear" # parse delete options
          require 'git-media/clear'
          GitMedia::Clear.run!
        when "sync"
          require 'git-media/sync'
          GitMedia::Sync.run!
        when 'status'
          require 'git-media/status'
          Trollop::options do
            opt :force, "Force status"
          end
          GitMedia::Status.run!
        else
          raise "unknown media subcommand #{cmd.inspect}"
        end
      
    end
  end
end
