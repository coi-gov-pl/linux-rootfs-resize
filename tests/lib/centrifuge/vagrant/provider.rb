require 'centrifuge/vagrant/vfile'
require 'centrifuge/cmdexec'

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
      end

      def cleanup
        Centrifuge.logger.debug "Running Vagrant cleanup #{@box} - #{@vfile}"
        unless @vfile.nil?
          vagrant 'destroy -f'
          @vfile.destroy
          @vfile = nil
        end
      end

      def workdir
        @vfile.workdir
      end

      private

      def exec_script(command, options)
        tmpname = Dir::Tmpname.make_tmpname 'centrifuge-', 'script.sh'
        remotescript = "/vagrant/#{tmpname}"
        localscript = "#{@vfile.workdir}/#{tmpname}"
        result = nil
        begin
          File.open(localscript, 'w') do |file|
            file.write(command)
            file.flush
            result = vagrant "ssh -c 'sudo -i bash -leo pipefail #{remotescript}'",
              options[:output] == :capture
          end
        ensure
          File.unlink(localscript)
        end
        result
      end

      def vagrant(subcommand, capture = false)
        command = "vagrant #{subcommand}"
        indent = 'vagrant'.rjust(7,' ')
        Centrifuge::Exec.exec(command,
          capture: capture,
          indent: "[#{indent}] ",
          chdir: @vfile.workdir
        )
      end

      def ensure_vfile
        if @vfile.nil?
          @vfile = Centrifuge::Vagrant::Vfile.new(@box)
          @vfile.create
        end
      end
    end
  end
end
