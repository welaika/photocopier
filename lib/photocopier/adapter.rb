require 'escape'
require 'tempfile'
require 'logger'
require 'active_support/all'

module Photocopier

  class Adapter
    attr_accessor :logger

    def put(file_path_or_string, remote_path)
      if File.exists? file_path_or_string
        put_file(file_path_or_string, remote_path)
      else
        file = Tempfile.new('put')
        file.write file_path_or_string
        file.close
        put_file(file.path, remote_path)
        file.unlink
      end
    end

    def put_file(file_path, remote_path); end
    def put_directory(local_path, remote_path, exclude = []); end

    def get(remote_path, file_path = nil); end
    def get_directory(remote_path, local_path, exclude = []); end

    def delete(remote_path); end

    protected

    def run(*args)
      command = Escape.shell_command(args)
      if logger.present?
        logger.info command
      end
      system command
    end
  end

end
