require 'photocopier/adapter'

describe Photocopier::Adapter do

  let(:adapter) { Photocopier::Adapter.new }

  context "define an adapter interface" do
    it "should expose all adapter methods" do
      [
        :put,
        :put_file,
        :put_directory,
        :get,
        :get_directory,
        :delete
      ].each do |sym|
        adapter.should respond_to(sym)
      end
    end
  end

  context "#put" do
    let(:file_path) { Tempfile.new("tmp").path }
    let(:remote_path) { stub }

    context "given a real file path" do
      it "should put a file" do
        adapter.should_receive(:put_file).with(file_path, remote_path)
        adapter.put(file_path, remote_path)
      end
    end

    context "given a string" do
      let(:string) { "foobar" }
      let(:file) { stub(:path => "path") }

      it "should write it to file, put it and remove the file" do
        Tempfile.stub(:new).and_return(file)

        file.should_receive(:write).with(string)
        file.should_receive(:close)
        adapter.should_receive(:put_file).with("path", remote_path)
        file.should_receive(:unlink)

        adapter.put(string, remote_path)
      end
    end

    context "#run" do
      let(:arg) { stub }
      let(:command) { stub }
      before(:each) {
        Escape.stub(:shell_command).with([arg]).and_return(command)
      }

      it "should delegate to Kernel system" do
        adapter.should_receive(:system).with(command)
        adapter.send(:run, arg)
      end

      context "given a logger" do
        let(:logger) { stub }

        it "should send the command to the logger" do
          adapter.logger = logger
          logger.should_receive(:info).with(command)
          adapter.send(:run, arg)
        end
      end
    end
  end
end
