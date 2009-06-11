module GitMedia
  class Smudge

    def self.run!
      media_buffer = GitMedia.setup_media_buffer
      can_download = false # TODO: read this from config and implement
      
      # read checksum size
      sha = STDIN.read(41)
      if STDIN.eof? && sha[40, 1] == "\n"
        # this is a media file
        media_file = File.join(media_buffer, sha.chomp)
        if File.exists?(media_file)
          STDERR.puts('recovering media : ' + sha)
          File.open(media_file, 'r') do |f|
            while data = f.read(4096) do
              print data
            end
          end
        else
          # TODO: download file if not in the media buffer area
          if !can_download
            STDERR.puts('media missing, saving placeholder : ' + sha)
            print "MEDIA:" + sha
          end
        end
      else
        # if more than 40 chars, just output
        print sha
        while data = STDIN.read(4096)
          print data
        end
      end
    end


  end
end