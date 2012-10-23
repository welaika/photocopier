require 'net/ftp'
require 'photocopier/adapter'
require 'fileutils'

module Photocopier
  class FTP < Adapter

    def initialize(options)
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

    def get_directory(remote_path, local_path)
      FileUtils.mkdir_p(local_path)
      lftp(local_path, remote_path, false)
    end

    def put_directory(local_path, remote_path)
      lftp(local_path, remote_path, true)
    end

    private

    def lftp(local, remote, reverse)
      run "lftp",
          "-c",
          [
            "set ftp:list-options -a",
            "open #{remote_ftp_url}",
            "mkdir -p #{remote}",
            "cd #{remote}",
            "lcd #{local}",
            lftp_mirror_arguments(reverse)
          ].join("; ")
    end

    def remote_ftp_url
      url = "ftp://"
      if options[:user].present?
        url << options[:user]
        url << ":#{options[:password]}" if options[:password].present?
        url << "@"
      end
      url << options[:host]
      url
    end

    def lftp_mirror_arguments(reverse)
      mirror = "mirror --delete --use-cache --verbose --allow-chown --allow-suid --no-umask --parallel=2"
      mirror << " --reverse" if reverse
      mirror
    end

    def lftp_mirrir_arguments(local, remote, reverse)

      arguments = []
      if gateway_options.any?
        arguments << ssh_command(gateway_options)
      end
      arguments << ssh_command(options)
      arguments.join(" ")
    end

    def session
      opts = options
      host = opts.delete(:host)
      user = opts.delete(:user)
      password = opts.delete(:password)
      @session ||= Net::FTP.open(host, user, password)
    end

  end

end
