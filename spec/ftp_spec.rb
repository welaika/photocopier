RSpec.describe Photocopier::FTP do
  it_behaves_like "a Photocopier adapter"

  let(:ftp) { Photocopier::FTP.new(options) }
  let(:options) do { host: "host", user: "user", password: "password" } end

  context "#session" do
    it "retrieves an FTP session" do
      expect(Net::FTP).to receive(:open).with("host", "user", "password")
      ftp.session
    end

    context "passive mode" do
      let(:options) do { host: "host", passive: true } end
      let(:ftp) { double('ftp').as_null_object }

      it "should enable passive mode" do
        allow(Net::FTP).to receive(:open).and_return(ftp)
        expect(ftp.session).to be_passive
      end
    end
  end

  context "#remote_ftp_url" do
    let(:options) do { host: "host" } end

    it "should build an ftp url" do
      expect(ftp.send(:remote_ftp_url)).to eq("ftp://host")
    end

    context "given an username" do
      let(:options) do { host: "host", user: "user" } end

      it "should add it to the url" do
        expect(ftp.send(:remote_ftp_url)).to eq("ftp://user@host")
      end

      context "given a password" do
        let(:options) do { host: "host", user: "user", password: "password" } end

        it "should add it to the url" do
          expect(ftp.send(:remote_ftp_url)).to eq("ftp://user:password@host")
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
      expect(ftp.send(:lftp_mirror_arguments, false, [])).to eq(lftp_arguments.join(" "))
    end

    it "should build args for reverse mirroring" do
      lftp_arguments << "--reverse"
      expect(ftp.send(:lftp_mirror_arguments, true, [])).to eq(lftp_arguments.join(" "))
    end

    it "should exclude files" do
      lftp_arguments << "--exclude-glob .git"
      expect(ftp.send(:lftp_mirror_arguments, false, [".git"])).to eq(lftp_arguments.join(" "))
    end
  end

  context "#lftp" do

    let(:remote) { "remote" }
    let(:local) { "local" }

    before(:each) do
      allow(ftp).to receive(:remote_ftp_url).and_return("remote_ftp_url")
      allow(ftp).to receive(:lftp_mirror_arguments).and_return("lftp_mirror_arguments")
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
      expect(ftp).to receive(:run).with(*lftp_command)
      ftp.send(:lftp, local, remote, false, [])
    end
  end

  context "adapter interface" do

    let(:remote_path) { double }
    let(:local_path)  { double }
    let(:file_path)   { double }
    let(:session)     { double }

    before(:each) do
      allow(ftp).to receive(:session).and_return(session)
    end

    context "#get" do
      it "should get a remote path" do
        expect(session).to receive(:get).with(remote_path, file_path)
        ftp.get(remote_path, file_path)
      end
    end

    context "#put_file" do
      it "should send a file to remote" do
        expect(session).to receive(:put).with(file_path, remote_path)
        ftp.put_file(file_path, remote_path)
      end
    end

    context "#delete" do
      it "should delete a remote path" do
        expect(session).to receive(:delete).with(remote_path)
        ftp.delete(remote_path)
      end
    end

    context "directories management" do
      let(:remote_path) { "remote_path" }
      let(:exclude_list) { [] }

      context "#get_directory" do
        it "should get a remote directory" do
          expect(FileUtils).to receive(:mkdir_p).with(local_path)
          expect(ftp).to receive(:lftp).with(local_path, remote_path, false, exclude_list)
          ftp.get_directory(remote_path, local_path, exclude_list)
        end
      end

      context "#put_directory" do
        it "should send a directory to remote" do
          expect(ftp).to receive(:lftp).with(local_path, remote_path, true, exclude_list)
          ftp.put_directory(local_path, remote_path, exclude_list)
        end
      end
    end
  end
end
