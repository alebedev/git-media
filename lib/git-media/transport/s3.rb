require 'git-media/transport'
require 's3'
require 'right_aws'

# git-media.transport s3
# git-media.s3bucket
# git-media.s3key
# git-media.s3secret

module GitMedia
  module Transport
    class S3 < Base

      def initialize(bucket, access_key_id = nil, secret_access_key = nil)    
        @s3 = RightAws::S3Interface.new(access_key_id, secret_access_key,
              {:multi_thread => true, :logger => Logger.new(File.expand_path('~/.git-media.s3.log'))})
    
        @bucket = bucket

        begin
          @buckets = @s3.list_all_my_buckets.map { |a| a[:name] }
        rescue RightAws::AwsError
          # Need to use STDERR because this might be called inside a filter
          STDERR.puts ("Failed to connect to storage backend (S3)")
          raise
        end

        if !@buckets.include?(bucket)
          # Need to use STDERR because this might be called inside a filter
          STDERR.puts ("Creating New Bucket")
          if @s3.create_bucket(bucket)
            @buckets << bucket
          end
        end
      end

      def read?
        @buckets.size > 0
      end

      def get_file(sha, to_file)
        to = File.new(to_file, File::CREAT|File::RDWR|File::BINARY)
        begin
          @s3.get(@bucket, sha) do |chunk|
            to.write(chunk)
          end
          to.close
          return true
        rescue RightAws::AwsError => e
          # Delete the file to make sure it is not expanded
          to.close
          File.delete(to_file)

          # Ugly, but AwsError does not seem to give me much choice
          if e.message.include?('NoSuchKey')
            STDERR.puts("Storage backend (S3) did not contain file : "+sha+", have you run 'git media sync' from all repos?")
            return false
          else
            # Need to use STDERR because this might be called inside a filter
            STDERR.puts ("Downloading file from S3 failed with error:\n" + e.message)
            return false
          end
        end
      end

      def write?
        @buckets.size > 0
      end

      def put_file(sha, from_file)
        @s3.put(@bucket, sha,  File.open(from_file,"rb"))
      end

      def get_unpushed(files)
        # Using a set instead of a list improves performance a lot
        # since it reduces the complexity from O(n^2) to O(n)
        keys = Set.new()

        # Apparently the list_bucket method only returns the first 1000 elements
        # This method however will continue to give back results until all elements
        # have been listed
        @s3.incrementally_list_bucket(@bucket) { |contents| 
          contents[:contents].each { |element|
            keys.add (element[:key])
          }
        }

        files.select do |f|
          !keys.include?(f)
        end
      end
    end
  end
end