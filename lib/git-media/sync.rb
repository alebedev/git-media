# find files that are placeholders (41 char) and download them
# upload files in media buffer that are not in offsite bin
require 'git-media/status'

module GitMedia
  module Sync

    def self.run!
      @push = GitMedia.get_push_transport
      @pull = GitMedia.get_pull_transport
      
      self.expand_references
      self.upload_local_cache
    end
    
    def self.expand_references
      status = GitMedia::Status.find_references
      status[:to_expand].each do |file, sha|
        cache_file = GitMedia.media_path(sha)
        puts "Expanding " + sha[0,8] + " : " + file
        @pull.pull(file, sha) if !File.exist?(cache_file)
        
        if File.exist?(cache_file)
          FileUtils.cp(cache_file, file)
          puts 'checked out'
        else
          puts 'could not get media'
        end
      end
    end
    
    def self.upload_local_cache
      # TODO: find files in media buffer and upload them
      # TODO: if --clear, remove them
    end
    
  end
end