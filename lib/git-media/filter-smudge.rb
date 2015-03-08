module GitMedia
  module FilterSmudge

    def self.print_stream(stream)
      # create a binary stream to write to stdout
      # this avoids messing up line endings on windows
      outstream = IO.try_convert(STDOUT)
      outstream.binmode

      while data = stream.read(4096) do
        print data
      end
    end

    def self.run!
      media_buffer = GitMedia.get_media_buffer
      
      # read checksum size
      orig = STDIN.readline(64)
      sha = orig.strip # read no more than 64 bytes
      if STDIN.eof? && sha.length == 40 && sha.match(/^[0-9a-fA-F]+$/) != nil
        # this is a media file
        media_file = File.join(media_buffer, sha.chomp)
        if File.exists?(media_file)
          STDERR.puts('Recovering media : ' + sha)
          File.open(media_file, 'rb') do |f|
            print_stream(f)
          end
        else
          # Read key from config
          auto_download = `git config git-media.autodownload`.chomp.downcase == "true"

          if auto_download

            pull = GitMedia.get_pull_transport

            cache_file = GitMedia.media_path(sha)
            if !File.exist?(cache_file)
              STDERR.puts ("Downloading : " + sha[0,8])
              # Download the file from backend storage
              # We have no idea what the final file will be (therefore nil)
              pull.pull(nil, sha)
            end

            STDERR.puts ("Expanding : " + sha[0,8])

            if File.exist?(cache_file)
              File.open(media_file, 'rb') do |f|
                print_stream(f)
              end
            else
              STDERR.puts ("Could not get media, saving placeholder : " + sha)
              puts orig
            end

          else
            STDERR.puts('Media missing, saving placeholder : ' + sha)
            # Print orig and not sha to preserve eventual newlines at end of file
            # To avoid git thinking the file has changed
            puts orig
          end
        end
      else
        # if it is not a 40 character long hash, just output
        STDERR.puts('Unknown git-media file format')
        print orig
        print_stream(STDIN)
      end
    end

  end
end
