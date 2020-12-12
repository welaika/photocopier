RSpec.describe Photocopier::FTP do
  it_behaves_like 'a Photocopier adapter'

  let(:ftp) { Photocopier::FTP.new(options) }
  let(:options) do
    {
      host: 'host',
      user: 'user',
      password: 'password',
      port: 2121
    }
  end

  context '#session' do
    it 'retrieves an FTP session' do
      expect(Net::FTP).to receive(:open).with(
        'host',
        username: 'user',
        password: 'password',
        port: 2121,
        passive: false,
        ssl: false
      )
      ftp.send(:session)
    end

    context 'passive mode' do
      let(:options) do
        { host: 'host', passive: true }
      end
      let(:ftp) { double('ftp').as_null_object }

      it 'should enable passive mode' do
        allow(Net::FTP).to receive(:open).and_return(ftp)
        expect(ftp.session).to be_passive
      end
    end
  end

  context '#remote_ftp_url' do
    let(:options) { { host: 'host' } }

    it 'should build an ftp url' do
      expect(ftp.send(:remote_ftp_url)).to eq('ftp://host')
    end

    context 'given an username' do
      let(:options) { { host: 'host', user: 'user' } }

      it 'should add it to the url' do
        expect(ftp.send(:remote_ftp_url)).to eq('ftp://user@host')
      end

      context 'given a password' do
        let(:options) { { host: 'host', user: 'user', password: 'password' } }

        it 'should add it to the url' do
          expect(ftp.send(:remote_ftp_url)).to eq('ftp://user:password@host')
        end
      end
    end

    context 'given a scheme (protocol)' do
      let(:options) { { scheme: 'ftps', host: 'host' } }

      it 'should add it to the url' do
        expect(ftp.send(:remote_ftp_url)).to eq('ftps://host')
      end

      context 'when called repeatedly' do
        it 'should add it to the url' do
          ftp.send(:remote_ftp_url)
          ftp.send(:remote_ftp_url)
          expect(ftp.send(:remote_ftp_url)).to eq('ftps://host')
        end
      end
    end
  end

  context '#lftp_mirror_arguments' do
    let(:lftp_arguments) do
      %w[
        mirror
        --delete
        --use-cache
        --verbose
        --no-perms
        --allow-suid
        --no-umask
        --parallel=5
      ]
    end

    it 'should build arguments for lftp' do
      expect(ftp.send(:lftp_mirror_arguments, false, [])).to eq(lftp_arguments.join(' '))
    end

    it 'should build args for reverse mirroring' do
      lftp_arguments << '--reverse --dereference'
      expect(ftp.send(:lftp_mirror_arguments, true, [])).to eq(lftp_arguments.join(' '))
    end

    it 'should exclude files' do
      lftp_arguments << '--exclude-glob *.git'
      expect(ftp.send(:lftp_mirror_arguments, false, ['*.git'])).to eq(lftp_arguments.join(' '))
    end
  end

  context '#lftp' do
    let(:options) do
      {
        host: 'example.com',
        user: 'user',
        password: "pass!\"',;$u&V^s",
        port: 2121
      }
    end

    let(:lftp_commands) do
      [
        'set ftp:list-options -a',
        'set ftp:passive-mode false',
        'set cmd:fail-exit true',
        "open -p #{ftp.inferred_port} #{options[:scheme] || 'ftp'}://user:pass%21%22%27%2C%3B%24u%26V%5Es@example.com",
        'find -d 1 remote\\ dir || mkdir -p remote\\ dir',
        'lcd local\\ dir',
        'cd remote\\ dir',
        'mirror --delete --use-cache --verbose --no-perms --allow-suid --no-umask --parallel=5 --reverse --dereference --exclude-glob .git --exclude-glob *.sql --exclude-glob bin/'
      ].join('; ')
    end

    it 'should build a lftp command with the right escaping' do
      expect(lftp_commands).to match('-p 2121')
      expect(ftp).to receive(:system).with("lftp -c '#{lftp_commands}'")
      ftp.send(:lftp, 'local dir', 'remote dir', true, ['.git', '*.sql', 'bin/'], options[:port])
    end

    context 'without a port expressed' do
      before do
        options.delete :port
      end
      let(:ftp) { Photocopier::FTP.new(options) }

      context 'if schema is sftp' do
        it 'uses default port 22' do
          options[:scheme] = 'sftp'

          expect(lftp_commands).to match('-p 22')
          expect(ftp).to receive(:system).with("lftp -c '#{lftp_commands}'")
          ftp.send(:lftp, 'local dir', 'remote dir', true, ['.git', '*.sql', 'bin/'])
        end
      end

      context 'if schema is ftp' do
        it 'uses default port 21' do
          options[:scheme] = 'ftp'

          expect(lftp_commands).to match('-p 21')
          expect(ftp).to receive(:system).with("lftp -c '#{lftp_commands}'")
          ftp.send(:lftp, 'local dir', 'remote dir', true, ['.git', '*.sql', 'bin/'])
        end
      end

      context 'if schema is ftps' do
        it 'uses default port 21' do
          options[:scheme] = 'ftps'

          expect(lftp_commands).to match('-p 21')
          expect(ftp).to receive(:system).with("lftp -c '#{lftp_commands}'")
          ftp.send(:lftp, 'local dir', 'remote dir', true, ['.git', '*.sql', 'bin/'])
        end
      end
    end
  end

  context 'adapter interface' do
    let(:remote_path) { double }
    let(:local_path)  { double }
    let(:file_path)   { double }
    let(:session)     { double }

    before(:each) do
      allow(ftp).to receive(:session).and_return(session)
    end

    context '#get' do
      it 'should get a remote path' do
        expect(session).to receive(:get).with(remote_path, file_path)
        ftp.get(remote_path, file_path)
      end
    end

    context '#put_file' do
      it 'should send a file to remote' do
        expect(session).to receive(:put_file).with(file_path, remote_path)
        ftp.put_file(file_path, remote_path)
      end
    end

    context '#delete' do
      it 'should delete a remote path' do
        expect(session).to receive(:delete).with(remote_path)
        ftp.delete(remote_path)
      end
    end

    context 'directories management' do
      let(:remote_path) { 'remote_path' }
      let(:exclude_list) { [] }

      context '#get_directory' do
        it 'should get a remote directory' do
          expect(FileUtils).to receive(:mkdir_p).with(local_path)
          expect(ftp).to receive(:lftp).with(local_path, remote_path, false, exclude_list, 2121)
          ftp.get_directory(remote_path, local_path, exclude_list)
        end
      end

      context '#put_directory' do
        it 'should send a directory to remote' do
          expect(ftp).to receive(:lftp).with(local_path, remote_path, true, exclude_list, 2121)
          ftp.put_directory(local_path, remote_path, exclude_list)
        end
      end
    end
  end
end
