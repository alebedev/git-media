require 'git-media/transport'

# move large media to local bin

# media.transport local
# media.local.path /opt/media

module GitMedia
  module Transport
    class Local < Base

      def initialize(path)
        @path = path
      end

      def read?
        File.exist?(@path)
      end

      def get_file(sha, to_file)
        from_file = File.join(@path, sha)
        if File.exists?(from_file)
          FileUtils.cp(from_file, to_file)
          return true
        end
        return false
      end

      def write?
        File.exist?(@path)
      end

      def put_file(sha, from_file)
        to_file = File.join(@path, sha)
        if File.exists?(from_file)
          FileUtils.cp(from_file, to_file)
          return true
        end
        return false
      end
      
      def get_unpushed(files)
        files.select do |f|
          !File.exist?(File.join(@path, f))
        end
      end
      
    end
  end
end
