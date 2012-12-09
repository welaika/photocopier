require 'photocopier/ftp'
require 'shared_examples_for_adapter'

describe Photocopier::FTP do
  it_behaves_like "a Photocopier adapter"

  let(:ftp) { Photocopier::FTP.new(options) }
  let(:options) do { :host => "host", :user => "user", :password => "password" } end

  context "#session" do
    it "retrieves an FTP session" do
      Net::FTP.should_receive(:open).with("host", "user", "password")
      ftp.session
    end

    context "passive mode" do
      let(:options) do { :host => "host", :passive => true } end

      it "should enable passive mode" do
        Net::FTP.stub(:open).and_return(stub.as_null_object)
        ftp.session.should be_passive
      end
    end
  end

  context "#remote_ftp_url" do
    let(:options) do { :host => "host" } end

    it "should build an ftp url" do
      ftp.send(:remote_ftp_url).should == "ftp://host"
    end

    context "given an username" do
      let(:options) do { :host => "host", :user => "user" } end

      it "should add it to the url" do
        ftp.send(:remote_ftp_url).should == "ftp://user@host"
      end

      context "given a password" do
        let(:options) do { :host => "host", :user => "user", :password => "password" } end

        it "should add it to the url" do
          ftp.send(:remote_ftp_url).should == "ftp://user:password@host"
        end
      end
    end
  end

  context "#lftp_mirror_arguments" do
    let(:lftp_arguments) do
      %w(
        mirror
        --delete
        --use-cache
        --verbose
        --allow-chown
        --allow-suid
        --no-umask
        --parallel=2
      )
    end

    it "should build arguments for lftp" do
      ftp.send(:lftp_mirror_arguments, false, []).should == lftp_arguments.join(" ")
    end

    it "should build args for reverse mirroring" do
      lftp_arguments << "--reverse"
      ftp.send(:lftp_mirror_arguments, true, []).should == lftp_arguments.join(" ")
    end

    it "should exclude files" do
      lftp_arguments << "--exclude-glob .git"
      ftp.send(:lftp_mirror_arguments, false, [".git"]).should == lftp_arguments.join(" ")
    end
  end

  context "#lftp" do

    let(:remote) { "remote" }
    let(:local) { "local" }

    before(:each) do
      ftp.stub(:remote_ftp_url).and_return("remote_ftp_url")
      ftp.stub(:lftp_mirror_arguments).and_return("lftp_mirror_arguments")
    end

    let(:lftp_command) do
      [
        "lftp",
        "-c",
        [
          "set ftp:list-options -a",
          "open remote_ftp_url",
          "mkdir -p #{remote}",
          "cd #{remote}",
          "lcd #{local}",
          "lftp_mirror_arguments"
        ].join("; ")
      ]
    end

    it "should build a lftp command" do
      ftp.should_receive(:run).with(*lftp_command)
      ftp.send(:lftp, local, remote, false, [])
    end
  end

  context "adapter interface" do

    let(:remote_path) { stub }
    let(:local_path)  { stub }
    let(:file_path)   { stub }
    let(:session)     { stub }

    before(:each) do
      ftp.stub(:session).and_return(session)
    end

    context "#get" do
      it "should get a remote path" do
        session.should_receive(:get).with(remote_path, file_path)
        ftp.get(remote_path, file_path)
      end
    end

    context "#put_file" do
      it "should send a file to remote" do
        session.should_receive(:put).with(file_path, remote_path)
        ftp.put_file(file_path, remote_path)
      end
    end

    context "#delete" do
      it "should delete a remote path" do
        session.should_receive(:delete).with(remote_path)
        ftp.delete(remote_path)
      end
    end

    context "directories management" do
      let(:remote_path) { "remote_path" }
      let(:exclude_list) { [] }

      context "#get_directory" do
        it "should get a remote directory" do
          FileUtils.should_receive(:mkdir_p).with(local_path)
          ftp.should_receive(:lftp).with(local_path, remote_path, false, exclude_list)
          ftp.get_directory(remote_path, local_path, exclude_list)
        end
      end

      context "#put_directory" do
        it "should send a directory to remote" do
          ftp.should_receive(:lftp).with(local_path, remote_path, true, exclude_list)
          ftp.put_directory(local_path, remote_path, exclude_list)
        end
      end
    end
  end
end
