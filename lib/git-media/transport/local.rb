require 'git-media/transport'

# move large media to local bin
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

      def push(sha)
      end

    end
  end
end
