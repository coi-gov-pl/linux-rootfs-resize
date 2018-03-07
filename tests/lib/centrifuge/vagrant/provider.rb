module Centrifuge
  module Vagrant
    class Provider
      attr_reader :box
      def initialize(box)
        @box = box
        @vfile = nil
      end

      def up
        Centrifuge.logger.debug "Running Vagrant up for #{@box}"
        ensure_vfile
        vagrant 'up'
      end

      def halt
        vagrant 'halt'
      end

      def exec(command, options)
        Centrifuge.logger.debug "Running remote command: #{command}"
        exec_script(command, options)
        # Mock response
        require 'ostruct'
        result = OpenStruct.new
        result.retcode = 0
        result.output = "42949672960\n"
        result
      end

      def cleanup
        Centrifuge.logger.debug "Running Vagrant cleanup #{@box} - #{@vfile}"
        unless @vfile.nil?
          vagrant 'destroy -f'
          @vfile.destroy
          @vfile = nil
        end
      end

      private

      def exec_script(command, options)
        tmpname = Dir::Tmpname.make_tmpname 'centrifuge-', 'script.sh'
        remotescript = "/vagrant/#{tmpname}"
        localscript = "#{@vfile.workdir}/#{tmpname}"
        begin
          File.open(localscript, 'w') do |file|
            file.write(command)
            vagrant "ssh -c 'bash -leo pipefail #{remotescript}'"
          end
        ensure
          File.unlink(localscript)
        end
      end

      def vagrant(subcommand, capture = false)
        Centrifuge.logger.debug ">>> vagrant #{subcommand}"

      end

      def ensure_vfile
        require 'centrifuge/vagrant/vfile'

        if @vfile.nil?
          @vfile = Centrifuge::Vagrant::Vfile.new(@box)
          @vfile.create
        end
      end
    end
  end
end
