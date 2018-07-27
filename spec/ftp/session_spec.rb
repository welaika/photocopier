RSpec.describe Photocopier::FTP::Session do
  let(:options) do
    {
      host: 'host',
      user: 'user',
      password: 'password',
      scheme: 'ftp'
    }
  end
  let(:ftp) { spy('ftp') }
  let(:sftp) { spy('sftp') }

  before do
    allow(Net::SFTP).to receive(:start).and_return(sftp)
    allow(Net::FTP).to receive(:open).and_return(ftp)
  end

  context "with ftp scheme" do
    let(:session) { described_class.new(options) }

    it "calls ftp methods" do
      expect(ftp).to receive(:get).once
      expect(ftp).to receive(:put).once
      expect(ftp).to receive(:delete).once

      session.get(:remote, :local)
      session.put_file(:local, :remote)
      session.delete(:remote)
    end
  end

  context "with sftp scheme" do
    before do
      options[:scheme] = 'sftp'
    end

    let(:session) { described_class.new(options) }

    it "calls sftp methods" do
      expect(sftp).to receive(:download!).once
      expect(sftp).to receive(:upload!).once
      expect(sftp).to receive(:remove!).once

      session.get(:remote, :local)
      session.put_file(:local, :remote)
      session.delete(:remote)
    end
  end
end
