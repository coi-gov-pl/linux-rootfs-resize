RSpec.shared_examples 'fully working linux-rootfs-resize script' do |context|
  centrifuge = Centrifuge::Runner.new(box: context[:box])

  after(:context) do
    centrifuge.cleanup
  end

  describe "testing with #{centrifuge}" do
    let(:cf) { centrifuge }

    # 1. vagrant up with mounting this repo
    describe 'performing vagrant up and mounting this repo' do
      it { expect{ cf.up }.not_to raise_error }
    end
    # 2. run install script
    describe 'running ./install script on VM' do
      subject { cf.run('sudo -i /centrifuge/install') }
      its(:retcode) { is_expected.to eq 0 }
    end
    # 3. turn off
    describe 'turning off VM' do
      it { expect{ cf.halt }.not_to raise_error }
    end
    # 4. resize drive
    describe 'resizing VM disk to 40 GiB' do
      describe 'by performing HDD resize' do
        it { expect{ cf.resize_disk(size: 40, unit: :GiB) }.not_to raise_error }
      end
      describe 'by booting VM back online' do
        it { expect{ cf.up }.not_to raise_error }
      end
    end
    # 5. check partition size
    describe 'resized partition of VM in megabytes' do
      subject { cf.run(Constants::Commands::GET_ROOT_PARTITION_SIZE, output: :catch) }
      let(:threshold) { (39.9 * 1024).to_i }

      its(:retcode) { is_expected.to eq 0 }
      describe :output do
        let(:output) { subject.output }
        let(:partition_size) { output.strip.to_i }
        it { expect(partition_size).to be >= threshold }
      end
    end
  end
end
