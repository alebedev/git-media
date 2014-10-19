require 'digest/sha1'
require 'fileutils'
require 'tempfile'

module GitMedia
  module FilterClean

    def self.run!
      
      # Read first 42 bytes
      # If the file is only 41 bytes long (as in the case of a stub)
      # it will only return a string with a length of 41
      data = STDIN.read(42)

      STDOUT.binmode

      if data != nil && data.length == 41 && data.match(/^[0-9a-fA-F]+\n$/)
        
        # Exactly 41 bytes long and matches the hex string regex
        # This is most likely a stub
        # TODO: Maybe add some additional marker in the files like
        # "[hex string]:git-media"
        # to really be able to say that a file is a stub

        STDOUT.write (data)
        STDERR.puts("Skipping unexpanded stub : " + data[0, 8])

      else

        # determine and initialize our media buffer directory
        media_buffer = GitMedia.get_media_buffer

        hashfunc = Digest::SHA1.new
        start = Time.now

        # read in buffered chunks of the data
        #  calculating the SHA and copying to a tempfile
        tempfile = Tempfile.new('media', :binmode => true)

        # Write the first 42 bytes
        if data != nil
          hashfunc.update(data)
          tempfile.write(data)
        end

        while data = STDIN.read(4096)
          hashfunc.update(data)
          tempfile.write(data)
        end
        tempfile.close

        # calculate and print the SHA of the data
        STDOUT.print hx = hashfunc.hexdigest 
        STDOUT.write("\n")

        # move the tempfile to our media buffer area
        media_file = File.join(media_buffer, hx)
        FileUtils.mv(tempfile.path, media_file)

        elapsed = Time.now - start
        STDERR.puts('Saving media : ' + hx + ' : ' + elapsed.to_s)
      end
    end

  end
end