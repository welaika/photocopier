require 'photocopier/ssh'
require 'shared_examples_for_adapter'

describe Photocopier::SSH do
  it_behaves_like "a Photocopier adapter"

  let(:ssh) { Photocopier::SSH.new(options) }
  let(:options) do { :host => "host", :user => "user" } end
  let(:gateway_config) do { :host => "gate_host", :user => "gate_user" } end
  let(:options_with_gateway) do
    {
      :host => "host",
      :user => "user",
      :gateway => gateway_config
    }
  end

  context "#session" do
    it "retrieves an SSH session" do
      Net::SSH.should_receive(:start).with("host", "user", {})
      ssh.session
    end

    context "given a gateway " do
      let(:options) { options_with_gateway }
      let(:gateway) { stub }

      it "goes through it to retrieve a session" do
        Net::SSH::Gateway.stub(:new).with("gate_host", "gate_user", {}).and_return(gateway)
        gateway.should_receive(:ssh).with("host", "user", {})
        ssh.session
      end
    end
  end

  context "#ssh_command" do
    let(:options) do { :host => "host" } end

    it "should build an ssh command" do
      ssh.send(:ssh_command, options).should == "ssh host"
    end

    context "given a port" do
      let(:options) do { :host => "host", :port => "port" } end
      it "should be added to the command" do
        ssh.send(:ssh_command, options).should == "ssh -p port host"
      end
    end

    context "given a user" do
      let(:options) do { :host => "host", :user => "user" } end
      it "should be added to the command" do
        ssh.send(:ssh_command, options).should == "ssh user@host"
      end
    end

    context "given a password" do
      let(:options) do { :host => "host", :password => "password" } end

      it "sshpass should be added to the command" do
        ssh.send(:ssh_command, options).should == "sshpass -p password ssh host"
      end
    end
  end

  context "#rsh_arguments" do
    it "should build arguments for rsync" do
      ssh.should_receive(:ssh_command).with(options)
      ssh.send(:rsh_arguments)
    end

    context "given a gateway" do
      let(:options) { options_with_gateway }
      it "should include gateway options" do
        ssh.should_receive(:ssh_command).with(gateway_config)
        ssh.should_receive(:ssh_command).with(options)
        ssh.send(:rsh_arguments)
      end
    end
  end

  context "#rsync" do
    before(:each) do
      ssh.stub(:rsh_arguments).and_return("rsh_arguments")
    end

    let(:rsync_command) {
      %w(
        rsync
        --progress
        -e
        rsh_arguments
        -rlpt
        --compress
        --omit-dir-times
        --delete
      )
    }

    it "should build an rsync command" do
      rsync_command << "source/" << "destination"
      ssh.should_receive(:run).with(*rsync_command)
      ssh.send(:rsync, "source", "destination")
    end

    context "given an exclude list" do
      it "should skip excluded paths" do
        rsync_command << "--exclude" << ".git"
        rsync_command << "source/" << "destination"
        ssh.should_receive(:run).with(*rsync_command)
        ssh.send(:rsync, "source", "destination", [".git"])
      end
    end
  end

  context "adapter interface" do

    let(:remote_path) { stub }
    let(:local_path)  { stub }
    let(:file_path)   { stub }
    let(:scp)         { stub }
    let(:session)     { stub(:scp => scp) }

    before(:each) do
      ssh.stub(:session).and_return(session)
    end

    context "#get" do
      it "should get a remote path" do
        scp.should_receive(:download!).with(remote_path, file_path)
        ssh.get(remote_path, file_path)
      end
    end

    context "#put_file" do
      it "should send a file to remote" do
        scp.should_receive(:upload!).with(file_path, remote_path)
        ssh.put_file(file_path, remote_path)
      end
    end

    context "#delete" do
      it "should delete a remote path" do
        ssh.should_receive(:exec!).with("rm -rf foo")
        ssh.delete("foo")
      end
    end

    context "directories management" do
      let(:remote_path) { "remote_path" }
      let(:exclude_list) { [] }

      context "#get_directory" do
        it "should get a remote directory" do
          FileUtils.should_receive(:mkdir_p).with(local_path)
          ssh.should_receive(:rsync).with(":remote_path", local_path, exclude_list)
          ssh.get_directory(remote_path, local_path, exclude_list)
        end
      end

      context "#put_directory" do
        it "should send a directory to remote" do
          ssh.should_receive(:rsync).with(local_path, ":remote_path", exclude_list)
          ssh.put_directory(local_path, remote_path, exclude_list)
        end
      end
    end
  end

end
