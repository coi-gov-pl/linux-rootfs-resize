RSpec.shared_examples 'fully working linux-rootfs-resize script' do |context|
  centrifuge = Centrifuge::Runner.new(box: context[:box])

  after(:context) do
    centrifuge.cleanup
  end

  describe "testing with #{centrifuge}" do
    let(:cf) { centrifuge }
    let(:size) { { size: 120 }.merge(context)[:size] }
    let(:home_size) { { home_size: 0 }.merge(context)[:home_size] }
    let(:swap_size) { { swap_size: 2 }.merge(context)[:swap_size] }
    let(:boot_size) { { boot_size: 1 }.merge(context)[:boot_size] }
    let(:freespace) { size - home_size - swap_size - boot_size }

    # 1. vagrant up with mounting this repo
    describe 'performing vagrant up and mounting this repo' do
      it { expect{ cf.up }.not_to raise_error }
    end
    # 2. run install script
    describe 'running ./install script on VM' do
      subject { cf.run('LRR_LOG_LEVEL=DEBUG /centrifuge/install') }
      its(:retcode) { is_expected.to eq 0 }
    end
    # 3. turn off
    describe 'turning off VM' do
      it { expect{ cf.halt }.not_to raise_error }
    end
    # 4. resize drive
    describe 'resizing VM disk to desired size' do
      describe 'by performing HDD resize' do
        it { expect{ cf.resize_disk(size: size, unit: :GiB) }.not_to raise_error }
      end
      describe 'by booting VM back online' do
        it { expect{ cf.up }.not_to raise_error }
      end
    end
    # 5. check partition size
    describe 'resized partition of VM in megabytes' do
      subject { cf.capture(Constants::Commands::GET_ROOT_PARTITION_SIZE) }
      let(:threshold) { (freespace * 1024).to_i }
      describe :output do
        let(:output) { subject.output }
        let(:partition_size) { output.strip.to_i }
        it { expect(partition_size).to be >= threshold }
      end
      its(:retcode) { is_expected.to eq 0 }
    end
  end
end
