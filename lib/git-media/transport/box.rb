require 'git-media/transport'
require 'boxr'
require 'shellwords'

# git-media.transport box
# git-media.boxclientid
# git-media.boxclientsecret
# git-media.boxredirecturi
# git-media.boxfolderid
# git-media.boxaccesstoken
# git-media.boxrefreshtoken

module GitMedia
  module Transport
    class Box < Base

      def initialize(client_id, client_secret, redirect_uri, folder_id, access_token, refresh_token)
        if access_token == "" || refresh_token == ""
          uri = Boxr::oauth_url(redirect_uri, box_client_id: client_id)
          print "(1) Paste following URL to your browser, and get your access code:\n\n#{uri}\n\n(2) Enter your access code: "
          code = STDIN.gets.chomp
          token =  Boxr::get_tokens(code, box_client_id: client_id, box_client_secret: client_secret)

          access_token = token.access_token
          refresh_token = token.refresh_token

          `git config git-media.boxaccesstoken #{access_token.shellescape}`
          `git config git-media.boxrefreshtoken #{refresh_token.shellescape}`
        end

        token_refresh_callback = lambda {|at, rt, id|
          `git config git-media.boxaccesstoken #{at.shellescape}`
          `git config git-media.boxrefreshtoken #{rt.shellescape}`
        }
        @box = Boxr::Client.new(access_token, refresh_token: refresh_token, box_client_id: client_id, box_client_secret: client_secret, &token_refresh_callback)
        @folder = @box.folder_from_id(folder_id)
      end

      def read?
        true
      end

      def get_file(sha, to_file)
        files = get_files(true)
        if files.has_key?(sha) == false
          files = get_files()
        end

        file_id = files[sha]
        if file_id == nil
          STDERR.puts("Storage backend (box) did not contain file : "+sha+", have you run 'git media sync' from all repos?")
          return false
        end

        file = @box.file_from_id(file_id)
        content = @box.download_file(file)
        File::open(to_file, "wb") do |f|
          f.write(content)
        end
      end

      def write?
        true
      end

      def put_file(sha, from_file)
        @box.upload_file(from_file, @folder)
      end

      def get_unpushed(files)
        remote_files = get_files()

        files.select do |f|
          !remote_files.has_key?(f)
        end
      end

      def get_files(use_cache = false)
        media_buffer = GitMedia.get_media_buffer
        cache_file = File.join(media_buffer, "cache")
        files = {}

        if use_cache
          File::exists?(cache_file) && File::open(cache_file) do |f|
            f.each do |s|
              r = s.strip.split(",")
              files[r[0]] = r[1]
            end
          end

          return files if files.length > 0
        end

        offset = 0
        limit = 100
        while (items = @box.folder_items(@folder, fields: [:id, :name], offset: offset, limit: limit)).length > 0
          items.each do |f|
            files[f[:name]] = f[:id]
          end
          offset = offset + limit
        end

        # cache update
        f = File::open(cache_file, "w")
        files.each do |name, id|
          f.puts "#{name},#{id}"
        end
        f.close

        return files
      end
    end
  end
end
