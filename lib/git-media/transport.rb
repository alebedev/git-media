module GitMedia
  module Transport
    class Base

      def pull(final_file, sha)
        to_file = GitMedia.media_path(sha)
        get_file(sha, to_file)
      end

      def push(sha)
        from_file = GitMedia.media_path(sha)
        put_file(sha, from_file)
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

      def get_unpushed(files)
        files
      end

    end
  end
end
