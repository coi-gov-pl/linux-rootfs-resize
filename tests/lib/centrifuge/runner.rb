require 'centrifuge/vagrant'
require 'centrifuge/hddresizer'

module Centrifuge
  class Runner
    def initialize(spec)
      @vagrant = Centrifuge::Vagrant.new(spec[:box])
      @hddresizer = Centrifuge::HddResizer.new(@vagrant)
    end

    def up
      @vagrant.up
    end

    def halt
      @vagrant.halt
    end

    def run(script, options = { output: :print })
      exec_on_vg(script, options)
    end

    def capture(script, options = { output: :capture })
      exec_on_vg(script, options)
    end

    def resize_disk(spec)
      @hddresizer.resize(spec)
    end

    def to_s
      "centrifuge via Vagrant of #{@vagrant.box}"
    end

    def cleanup
      @vagrant.cleanup
    end

    private

    def exec_on_vg(command, options)
      defaults = { output: :print }
      calculated = defaults.merge(options)
      @vagrant.exec(command, calculated)
    end
  end
end
