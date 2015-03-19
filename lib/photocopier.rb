require 'tempfile'
require 'logger'
require 'fileutils'
require 'net/ftp'
require 'net/ssh'
require 'net/ssh/gateway'
require 'net/scp'
require 'fileutils'
require 'shellwords'
require 'active_support/all'

require 'photocopier/adapter'
require "photocopier/ssh"
require "photocopier/ftp"
