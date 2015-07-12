module Photocopier
  class FTP < Adapter

    def initialize(options = {})
      @options = options
    end

    def options
      @options.clone
    end

    def get(remote_path, file_path = nil)
      session.get remote_path, file_path
    end

    def put_file(file_path, remote_path)
      session.put file_path, remote_path
    end

    def delete(remote_path)
      session.delete(remote_path)
    end

    def get_directory(remote_path, local_path, exclude = [])
      FileUtils.mkdir_p(local_path)
      lftp(local_path, remote_path, false, exclude)
    end

    def put_directory(local_path, remote_path, exclude = [])
      lftp(local_path, remote_path, true, exclude)
    end

    private

    def session
      if @session.nil?
        @session = Net::FTP.open(options[:host], options[:user], options[:password])
        @session.passive = options[:passive] if options.has_key?(:passive)
      end
      @session
    end

    def lftp(local, remote, reverse, exclude)
      command = [
          "set ftp:list-options -a",
          "set cmd:fail-exit true",
          "open #{remote_ftp_url}",
          "mkdir -p #{Shellwords.escape(remote)}",
          "cd #{Shellwords.escape(remote)}",
          "lcd #{Shellwords.escape(local)}",
          lftp_mirror_arguments(reverse, exclude)
      ].join("; ")

      run "lftp -c '#{command}'"
    end

    def remote_ftp_url
      url = options[:scheme].presence || "ftp"
      url << "://"
      if options[:user].present?
        url << CGI.escape(options[:user])
        url << ":#{CGI.escape(options[:password])}" if options[:password].present?
        url << "@"
      end
      url << options[:host]
      url
    end

    def lftp_mirror_arguments(reverse, exclude = [])
      mirror = "mirror --delete --use-cache --verbose --allow-chown --allow-suid --no-umask --parallel=5"
      mirror << " --reverse" if reverse
      exclude.each do |glob|
        mirror << " --exclude-glob #{glob}" # NOTE do not use Shellwords.escape here
      end
      mirror
    end
  end
end
