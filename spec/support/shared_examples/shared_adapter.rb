RSpec.shared_examples_for 'a Photocopier adapter' do
  let(:adapter) { described_class.new }

  context 'adapter interface' do
    it 'should expose all adapter methods' do
      %i[
        put
        put_file
        put_directory
        get
        get_directory
        delete
      ].each do |sym|
        expect(adapter).to respond_to(sym)
      end
    end
  end

  context '#put' do
    let(:file_path) { Tempfile.new('tmp').path }
    let(:remote_path) { double }

    context 'given a real file path' do
      it 'should put a file' do
        expect(adapter).to receive(:put_file).with(file_path, remote_path)
        adapter.put(file_path, remote_path)
      end
    end

    context 'given a string' do
      let(:string) { 'foobar' }
      let(:file) { double(path: 'path') }

      it 'should write it to file, put it and remove the file' do
        allow(Tempfile).to receive(:new).and_return(file)

        expect(file).to receive(:write).with(string)
        expect(file).to receive(:close)
        expect(adapter).to receive(:put_file).with('path', remote_path)
        expect(file).to receive(:unlink)

        adapter.put(string, remote_path)
      end
    end

    context '#run' do
      let(:command) { double }

      it 'should delegate to Kernel system' do
        expect(adapter).to receive(:system).with(command)
        adapter.send(:run, command)
      end

      context 'given a logger' do
        let(:logger) { double }

        it 'should send the command to the logger' do
          allow(adapter).to receive(:system)
          adapter.logger = logger
          expect(logger).to receive(:info).with(command)
          adapter.send(:run, command)
        end
      end
    end
  end
end
