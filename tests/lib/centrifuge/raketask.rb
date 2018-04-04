require 'centrifuge'

module Centrifuge
  class RakeTask < Rake::TaskLib

    attr_accessor :size, :vagrantfile

    def initialize(name = :centrifuge, *args, &task_block)
      @size = {}
      @vagrantfile = nil
      namespace name do

        desc 'Resizes HDD of Vagrant'
        task(:resize, [:machine]) do |t, task_args|
          task_args.with_defaults machine: 'centos7'
          RakeFileUtils.__send__(:verbose, verbose) do
            task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block
            run_task verbose, task_args
          end
        end
      end
    end

    private

    class VagrantWrap
      def initialize(rtask)
        @rtask = rtask
      end

      def workdir
        File.dirname(@rtask.vagrantfile)
      end
    end

    def run_task(verbose, args)
      puts "Running task"
      machine = args[:machine]
      vagrant = VagrantWrap.new(self)

      resizer = Centrifuge::HddResizer.new(vagrant, machine)
      resizer.resize(@size)
    end
  end
end
