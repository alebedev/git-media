require 'digest/sha1'
require 'fileutils'
require 'tempfile'

module GitMedia
  module Clean

    def self.run!
      # determine and initialize our media buffer directory
      media_buffer = GitMedia.setup_media_buffer

      hashfunc = Digest::SHA1.new
      start = Time.now

      # TODO: read first 41 bytes and see if this is a stub
      
      # read in buffered chunks of the data
      #  calculating the SHA and copying to a tempfile
      tempfile = Tempfile.new('media')
      while data = STDIN.read(4096)
        hashfunc.update(data)
        tempfile.write(data)
      end
      tempfile.close

      # calculate and print the SHA of the data
      puts hx = hashfunc.hexdigest 

      # move the tempfile to our media buffer area
      media_file = File.join(media_buffer, hx)
      FileUtils.mv(tempfile.path, media_file)

      elapsed = Time.now - start
      STDERR.puts('Saving media : ' + hx + ' : ' + elapsed.to_s)
    end

  end
end