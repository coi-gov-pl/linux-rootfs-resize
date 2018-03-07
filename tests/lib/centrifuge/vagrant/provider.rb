require 'centrifuge/vagrant/vfile'
require 'ostruct'
require 'open3'
require 'nio'

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

      private

      def exec_script(command, options)
        tmpname = Dir::Tmpname.make_tmpname 'centrifuge-', 'script.sh'
        remotescript = "/vagrant/#{tmpname}"
        localscript = "#{@vfile.workdir}/#{tmpname}"
        result = nil
        begin
          File.open(localscript, 'w') do |file|
            file.write(command)
            result = vagrant "ssh -c 'bash -leo pipefail #{remotescript}'",
              options[:output] == :capture
          end
        ensure
          File.unlink(localscript)
        end
        result
      end

      def vagrant(subcommand, capture = false)
        result = OpenStruct.new
        result.retcode = nil
        result.output = nil

        command = "vagrant #{subcommand}"
        Centrifuge.logger.debug ">>> #{command}"
        Dir.chdir(@vfile.workdir) do
          if capture
            output, status = Open3.capture2(command)
            Centrifuge.logger.debug "Captured output: #{output}"
            result.output = output
            result.retcode = status.exitstatus
          else
            result.retcode = streaming command
          end
        end
        result
      end

      def streaming(command)
        selector = NIO::Selector.new

        stdin, stdout, stderr, thread = Open3.popen3(command)

        monitor_stdout = selector.register(stdout, :r)
        monitor_stderr = selector.register(stderr, :r)

        monitor_stdout.value = proc {
          line = monitor_stdout.io.read_nonblock(4096)
          Centrifuge.logger.info ">>> #{line.rstrip}"
        }
        monitor_stderr.value = proc {
          line = monitor_stderr.io.read_nonblock(4096)
          Centrifuge.logger.info ">>> #{line.rstrip}"
        }

        timeout = 30 * 60 # seconds

        loop do
          begin
            ready = selector.select(timeout)
            raise 'Command timeout' if ready.nil?

            ready.each { |m| m.value.call }
          rescue EOFError
            break
          end
        end

        thread.value.exitstatus
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
