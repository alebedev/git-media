require 'rubygems'
require 'bundler/setup'

require 'trollop'
require 'fileutils'
#

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
    self.get_transport
  end

  def self.get_credentials_from_netrc(url)
    require 'uri'
    require 'netrc'

    uri = URI(url)
    hostname = uri.host
    unless hostname
      raise "Cannot identify hostname within git-media.webdavurl value"
    end
    netrc = Netrc.read
    netrc[hostname]
  end

  def self.get_transport
    transport = `git config git-media.transport`.chomp
    case transport
    when ""
      raise "git-media.transport not set"

    when "scp"
      require 'git-media/transport/scp'

      user = `git config git-media.scpuser`.chomp
      host = `git config git-media.scphost`.chomp
      path = `git config git-media.scppath`.chomp
      port = `git config git-media.scpport`.chomp
      if user === ""
        raise "git-media.scpuser not set for scp transport"
      end
      if host === ""
        raise "git-media.scphost not set for scp transport"
      end
      if path === ""
        raise "git-media.scppath not set for scp transport"
      end
      GitMedia::Transport::Scp.new(user, host, path, port)

    when "local"
      require 'git-media/transport/local'

      path = `git config git-media.localpath`.chomp
      if path === ""
        raise "git-media.localpath not set for local transport"
      end
      GitMedia::Transport::Local.new(path)

    when "s3"
      require 'git-media/transport/s3'

      bucket = `git config git-media.s3bucket`.chomp
      key = `git config git-media.s3key`.chomp
      secret = `git config git-media.s3secret`.chomp
      if bucket === ""
        raise "git-media.s3bucket not set for s3 transport"
      end
      if key === ""
        raise "git-media.s3key not set for s3 transport"
      end
      if secret === ""
        raise "git-media.s3secret not set for s3 transport"
      end
      GitMedia::Transport::S3.new(bucket, key, secret)

    when "atmos"
      require 'git-media/transport/atmos_client'

      endpoint = `git config git-media.endpoint`.chomp
      uid = `git config git-media.uid`.chomp
      secret = `git config git-media.secret`.chomp
      tag = `git config git-media.tag`.chomp

      if endpoint == ""
        raise "git-media.endpoint not set for atmos transport"
      end

      if uid == ""
        raise "git-media.uid not set for atmos transport"
      end

      if secret == ""
        raise "git-media.secret not set for atmos transport"
      end
      GitMedia::Transport::AtmosClient.new(endpoint, uid, secret, tag)
    when "webdav"
      require 'git-media/transport/webdav'

      url = `git config git-media.webdavurl`.chomp
      user = `git config git-media.webdavuser`.chomp
      password = `git config git-media.webdavpassword`.chomp
      verify_server = `git config git-media.webdavverifyserver`.chomp == 'true'
      binary_transfer = `git config git-media.webdavbinarytransfer`.chomp == 'true'
      if url == ""
        raise "git-media.webdavurl not set for webdav transport"
      end
      if user == ""
        user, password = self.get_credentials_from_netrc(url)
      end
      if !user
        raise "git-media.webdavuser not set for webdav transport"
      end
      if !password
        raise "git-media.webdavpassword not set for webdav transport"
      end
      GitMedia::Transport::WebDav.new(url, user, password, verify_server, binary_transfer)
    when "box"
      require 'git-media/transport/box'

      client_id = `git config git-media.boxclientid`.chomp
      client_secret = `git config git-media.boxclientsecret`.chomp
      redirect_uri = `git config git-media.boxredirecturi`.chomp
      folder_id = `git config git-media.boxfolderid`.chomp

      access_token = `git config git-media.boxaccesstoken`.chomp
      refresh_token = `git config git-media.boxrefreshtoken`.chomp
      if client_id == ""
        raise "git-media.boxclientid not set for box transport"
      end
      if client_secret == ""
        raise "git-media.boxclientsecret not set for box transport"
      end
      if redirect_uri == ""
        raise "git-media.boxredirecturi not set for box transport"
      end
      if folder_id == ""
        raise "git-media.boxfolderid not set for box transport"
      end
      GitMedia::Transport::Box.new(client_id, client_secret, redirect_uri, folder_id, access_token, refresh_token)
    else
      raise "Invalid transport #{transport}"
    end
  end

  def self.get_pull_transport
    self.get_transport
  end

  module Application
    def self.run!

      if !system('git rev-parse')
        return
      end

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
          opts = Trollop::options do
            opt :force, "Force status"
            opt :short, "Short status"
          end
          GitMedia::Status.run!(opts)
        when 'retroactively-apply'
          require 'git-media/filter-branch'
          GitMedia::FilterBranch.clean!
          arg2 = "--index-filter 'git media index-filter #{ARGV.shift}'"
          system("git filter-branch #{arg2} --tag-name-filter cat -- --all")
          GitMedia::FilterBranch.clean!
        when 'index-filter'
          require 'git-media/filter-branch'
          GitMedia::FilterBranch.run!
        else
    print <<EOF
usage: git media sync|status|clear

  sync                 Sync files with remote server

  status               Show files that are waiting to be uploaded and file size
                       --short:  Displays a shorter status message

  clear                Upload and delete the local cache of media files

  retroactively-apply  [Experimental] Rewrite history to add files from previous commits to git-media
                       Takes a single argument which is an absolute path to a file which should contain all file paths to rewrite
                       This file could for example be generated using
                       'git log --pretty=format: --name-only --diff-filter=A | sort -u | egrep ".*\.(jpg|png)" > to_rewrite'

EOF
        end

    end
  end
end
