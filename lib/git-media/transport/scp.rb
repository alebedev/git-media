require 'git-media/transport'

# move large media to local bin

# media.transport local
# media.local.path /opt/media

module GitMedia
  module Transport
    class Scp < Base

      def initialize(user, host, path)
	@user = user
	@host = host
        @path = path
      end

      def exist?(file)
	if `ssh #{@user}@#{@host} [ -f "#{file}" ] && echo 1 || echo 0`.chomp == "1"
	  puts file + " exists"
	  return true
	else
	  puts file + " doesn't exists"
	  return false
	end
      end

      def read?
	return true
      end

      def get_file(sha, to_file)
        from_file = @user+"@"+@host+":"+File.join(@path, sha)
	`scp "#{from_file}" "#{to_file}"`
        if $? == 0
	  puts sha+" downloaded"
          return true
        end
	puts sha+" download fail"
        return false
      end

      def write?
	return true
      end

      def put_file(sha, from_file)
        to_file = @user+"@"+@host+":"+File.join(@path, sha)
	`scp "#{from_file}" "#{to_file}"`
        if $? == 0
	  puts sha+" uploaded"
          return true
        end
	puts sha+" upload fail"
        return false
      end
      
      def get_unpushed(files)
        files.select do |f|
          !self.exist?(File.join(@path, f))
        end
      end
      
    end
  end
end
