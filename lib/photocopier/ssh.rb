require 'net/ssh'
require 'net/ssh/gateway'
require 'net/scp'
require 'fileutils'

require 'photocopier/adapter'

module Photocopier
  class SSH < Adapter

    attr_reader :gateway_options, :rsync_options

    def initialize(options = {})
      @options = options
      @gateway_options = options.delete(:gateway)
      @rsync_options = options.delete(:rsync_options)
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

      @session ||= if gateway_options
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

    def rsync_command
      [
        "rsync",
        "--progress",
        "-e",
        rsh_arguments,
        "-rlpt",
        "--compress",
        "--omit-dir-times",
        "--delete",
        rsync_options
      ].compact
    end

    def rsync(source, destination, exclude = [])
      command = rsync_command

      exclude.map do |glob|
        command << "--exclude"
        command << glob
      end

      command << "#{source}/" << destination

      run *command
    end

    def rsh_arguments
      arguments = []
      arguments << ssh_command(gateway_options) if gateway_options
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
      return unless gateway_options

      opts = gateway_options.clone
      host = opts.delete(:host)
      user = opts.delete(:user)

      @gateway ||= Net::SSH::Gateway.new(host, user, opts)
    end

  end
end
