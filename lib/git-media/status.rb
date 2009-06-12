require 'pp'

module GitMedia
  module Status

    def self.run!
      # look for files with 41 bytes, if file on disk matches and all hex
      r = self.find_references
      pp r
    end
    
    # find tree entries that are likely media references
    def self.find_references
      references = {:to_expand => [], :expanded => [], :deleted => []}
      files = `git ls-tree -l -r HEAD`.split("\n")
      files = files.map { |f| s = f.split("\t"); [s[0].split(' ').last, s[1]] }
      files = files.select { |f| f[0] == '41' } # it's the right size
      files.each do |tree_size, fname|
        if size = File.size?(fname)
          if size == tree_size.to_i
            # TODO: read in the data and verify that it's a sha + newline
            sha = File.read(fname).strip
            if sha.length == 40
              references[:to_expand] << [fname, sha]
            end
          else
            references[:expanded] << fname
          end
        else
          # file was deleted
          references[:deleted] << fname
        end
      end
      references
    end
  end
end