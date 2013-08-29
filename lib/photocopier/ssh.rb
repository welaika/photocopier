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
      exec!("rm -rf #{remote_path}")
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
      @session ||= if gateway_options.any?
                     gateway.ssh(host, user, opts)
                   else
                     Net::SSH.start(host, user, opts)
                   end
    end

    def exec!(cmd)
      stdout = ""
      stderr = ""
      exit_code = nil
      session.open_channel do |channel|
        channel.exec(cmd) do |ch, success|
          channel.on_data do |ch, data|
            stdout << data
          end
          channel.on_extended_data do |ch, type, data|
            stderr << data
          end
          channel.on_request("exit-status") do |ch, data|
            exit_code = data.read_long
          end
        end
      end
      session.loop
      [ stdout, stderr, exit_code ]
    end

    def rsync(source, destination, exclude = [])
      command = [
        "rsync", "--progress", "-e", rsh_arguments, "-rlpt", "--compress",
        "--omit-dir-times", "--delete", rsync_options
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
        arguments << ssh_command(gateway_options)
      end
      arguments << ssh_command(options)
      arguments.join(" ")
    end

    def ssh_command(opts)
      command = "ssh "
      command << "-p #{opts[:port]} " if opts[:port].present?
      command << "#{opts[:user]}@" if opts[:user].present?
      command << opts[:host]
      if opts[:password]
        command = "sshpass -p #{opts[:password]} #{command}"
      end
      command
    end

    private

    def gateway
      opts = gateway_options
      host = opts.delete(:host)
      user = opts.delete(:user)
      @gateway ||= Net::SSH::Gateway.new(host, user, opts)
    end

    def gateway_options
      options[:gateway] || {}
    end

    def rsync_options
      options[:rsync_options] || ""
    end

  end
end
