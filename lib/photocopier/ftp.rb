module Photocopier
  class FTP < Adapter
    # rubocop:disable Lint/MissingSuper
    def initialize(options = {})
      @options = options
    end
    # rubocop:enable Lint/MissingSuper

    def options
      @options.clone
    end

    def get(remote_path, file_path = nil)
      session.get remote_path, file_path
    end

    def put_file(file_path, remote_path)
      session.put_file file_path, remote_path
    end

    def delete(remote_path)
      session.delete(remote_path)
    end

    def get_directory(remote_path, local_path, exclude = [])
      FileUtils.mkdir_p(local_path)
      lftp(local_path, remote_path, false, exclude, options[:port])
    end

    def put_directory(local_path, remote_path, exclude = [])
      lftp(local_path, remote_path, true, exclude, options[:port])
    end

    def inferred_port
      if options[:port].nil? && options[:scheme] == 'sftp'
        22
      elsif options[:port].nil?
        21
      else
        options[:port]
      end
    end

    private

    def session
      @session ||= Session.new(options)
    end

    def lftp(local, remote, reverse, exclude, port = nil)
      remote = Shellwords.escape(remote)
      local = Shellwords.escape(local)
      command = [
        'set ftp:list-options -a',
        "set ftp:passive-mode #{options[:passive] || 'false'}",
        'set cmd:fail-exit true',
        "open -p #{port || inferred_port} #{remote_ftp_url}",
        "find -d 1 #{remote} || mkdir -p #{remote}",
        "lcd #{local}",
        "cd #{remote}",
        lftp_mirror_arguments(reverse, exclude)
      ].join('; ')

      run "lftp -c '#{command}'"
    end

    def remote_ftp_url
      url = options[:scheme].dup.presence || 'ftp'
      url << '://'
      if options[:user].present?
        url << CGI.escape(options[:user])
        url << ":#{CGI.escape(options[:password])}" if options[:password].present?
        url << '@'
      end
      url << options[:host]
      url
    end

    def lftp_mirror_arguments(reverse, exclude = [])
      mirror = 'mirror --delete --use-cache --verbose' \
               ' --no-perms --allow-suid --no-umask --parallel=5'
      mirror << ' --reverse --dereference' if reverse
      exclude.each do |glob|
        mirror << " --exclude-glob #{glob}" # NOTE: do not use Shellwords.escape here
      end
      mirror
    end
  end
end
