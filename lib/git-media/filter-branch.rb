require 'set'
require 'git-media/filter-clean'
require 'fileutils'

include Process

module GitMedia
  module FilterBranch

    def self.get_temp_buffer
      @@git_dir ||= `git rev-parse --git-dir`.chomp
      temp_buffer = File.join(@@git_dir, 'media/filter-branch')
      FileUtils.mkdir_p(temp_buffer) if !File.exist?(temp_buffer)
      return temp_buffer
    end

    def self.clean!
      tmp_buffer = get_temp_buffer
      FileUtils.rm_r (tmp_buffer)
      FileUtils.rmdir (tmp_buffer)
    end

    def self.run!
      # Rewriting of history
      # Inspired by how git-fat does it

      inputfiles = ARGF.read.split("\n").map { |s| s.downcase }.to_set
      all_files = `git ls-files -s`.split("\n")
      filecount = all_files.length.to_s

      # determine and initialize our media buffer directory
      media_buffer = GitMedia.get_media_buffer

      tmp_buffer = get_temp_buffer

      STDOUT.write ("  ")

      index = 0
      prevLength = 0


      fileLists = [[],[],[],[]]
      all_files.each_with_index do |f, i|
        fileLists[i % fileLists.length].push (f)
      end

      update_index_reader, update_index_writer = IO.pipe
      update_index_pid = spawn("git update-index --index-info", :in=>update_index_reader)
      update_index_reader.close
      mutex = Mutex.new
          
      threads = []
      fileLists.each_with_index do |files, thread_index|

        fls = files
        thread = Thread.new do

          fls.each do |line|
            index += 1

            head, filepath = line.split("\t")
            filepath.strip!

            if not inputfiles.include? (filepath.downcase)
              next
            end

            mode, blob, stagenumber = head.split()

            # Skip symlinks
            if mode == "120000"
              next
            end

            # 1   Find cached git-hash of the media stub
            # 1.2 If not found, calculate it
            # 1.3 store object in media buffer
            # 1.4 save the hash in the cache
            # 2   Replace object with git-hash of the stub
            
            #1
            hash_file_path = File.join(tmp_buffer, blob)

            hash_of_stub = nil
            if File.exists?(hash_file_path)

              File.open(hash_file_path, "rb") do |f|
                hash_of_stub = f.read.strip()
              end
            else

              # Only show progress output for thread 0 because otherwise the thread
              # output might get messed up by multiple threads writing at the same time
              if thread_index == 0
                # Erase previous output text
                # \b is backspace
                prevLength.times {
                  STDOUT.write("\b")
                  STDOUT.write(" ")
                  STDOUT.write("\b")
                }

                line = "Filtering " + index.to_s + " of " + filecount + " : " + filepath
                prevLength = line.length
                STDOUT.write (line)
              end

              # pipes roughly equivalent to
              # cat-file | clean | hash | update-index
              # 1.2, 1.3

              gitcat_reader, gitcat_writer= IO.pipe
              gitcat_pid = spawn("git cat-file blob " + blob, :out=>gitcat_writer, :close_others=>true)

              # We are not using it, so close it
              gitcat_writer.close

              githash_reader, githash_writer= IO.pipe
              githash_output_reader, githash_output_writer= IO.pipe
              githash_pid = spawn("git hash-object -w --stdin", :in=>githash_reader, :out=>githash_output_writer)
              githash_output_writer.close
              githash_reader.close

              GitMedia::FilterClean.run!(gitcat_reader, githash_writer, false)
              
              gitcat_reader.close
              githash_writer.close

              hash_of_stub = githash_output_reader.read().strip()

              # 1.4
              cache = File.new(hash_file_path, File::CREAT|File::RDWR|File::BINARY)
              cache.write(hash_of_stub)
              cache.close

              wait (githash_pid)
              wait (gitcat_pid)
            end

            # 2
            update = mode + " " + hash_of_stub + " " + stagenumber + "\t" + filepath + "\n"

            # Synchronize with a mutex to avoid multiple
            # threads writing to the pipe at the same time
            mutex.synchronize do
              update_index_writer.write(update)
            end
          end
        end

        threads.push(thread)
      end

      threads.each do |thread|
        thread.join
      end

      update_index_writer.close()
      wait(update_index_pid)
    end
  end
end