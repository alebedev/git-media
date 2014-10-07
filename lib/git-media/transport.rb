require 'xz'

module GitMedia
  module Transport
    class Base

      def pull(final_file, sha)
        to_file = GitMedia.media_path(sha)
        to_filez = to_file + ".xz"
        get_file(sha, to_filez)
        XZ.decompress_file(to_filez, to_file)
      end

      def push(sha)
        from_file = GitMedia.media_path(sha)
        from_filez = from_file + ".xz"
        XZ.compress_file(from_file, from_filez)
        put_file(sha, from_filez)
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
