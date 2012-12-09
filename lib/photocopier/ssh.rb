require 'net/ssh'
require 'net/ssh/gateway'
require 'net/scp'
require 'fileutils'

require 'photocopier/adapter'

module Photocopier
  class SSH < Adapter

    def initialize(options = {})
      @options = options
    end

    def options
      @options.clone
    end

    def get(remote_path, file_path = nil)
      session.scp.download! remote_path, file_path
    end

    def put_file(file_path, remote_path)
      session.scp.upload! file_path, remote_path
    end

    def delete(remote_path)
      session.exec!("rm -rf #{remote_path}")
    end

    def get_directory(remote_path, local_path, exclude = [])
      FileUtils.mkdir_p(local_path)
      rsync ":#{remote_path}", local_path, exclude
    end

    def put_directory(local_path, remote_path, exclude = [])
      rsync local_path, ":#{remote_path}", exclude
    end

    def session
      opts = options
      host = opts.delete(:host)
      user = opts.delete(:user)
      opts.delete(:gateway)
      opts.delete(:sshpass)
      @session ||= if gateway_options.any?
                     gateway.ssh(host, user, opts)
                   else
                     Net::SSH.start(host, user, opts)
                   end
    end

    private

    def rsync(source, destination, exclude = [])
      command = [
        "rsync", "--progress", "-e", rsh_arguments, "--archive", "--compress",
        "--omit-dir-times", "--delete"
      ]

      exclude.map do |glob|
        command << "--exclude"
        command << glob
      end

      command << "#{source}/"
      command << destination

      run *command
    end

    def rsh_arguments
      arguments = []
      if gateway_options.any?
        arguments << ssh_command(gateway_options, options[:sshpass])
      end
      arguments << ssh_command(options, gateway_options[:sshpass])
      arguments.join(" ")
    end

    def ssh_command(opts, use_sshpass=true)
      command = "ssh "
      command << "-p #{opts[:port]} " if opts[:port].present?
      command << "#{opts[:user]}@" if opts[:user].present?
      command << opts[:host]
      if opts[:password] && use_sshpass
        command = "sshpass -p #{opts[:password]} #{command}"
      end
      command
    end

    def gateway
      opts = gateway_options
      host = opts.delete(:host)
      user = opts.delete(:user)
      opts.delete(:sshpass)
      @gateway ||= Net::SSH::Gateway.new(host, user, opts)
    end

    def gateway_options
      options[:gateway] || {}
    end

  end
end
