module GitMedia
  module Transport
    class Base

      def pull(final_file, sha)
        to_file = GitMedia.media_path(sha)
        get_file(sha, to_file)
      end

      ## OVERWRITE ##
      
      def read?
        false
      end

      def write?
        false
      end

      def get_file(sha, to_file)
        false
      end

      def put_file(sha, to_file)
        false
      end
      
    end
  end
end