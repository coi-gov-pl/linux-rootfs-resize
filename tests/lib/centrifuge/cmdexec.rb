require 'ostruct'
require 'open3'
require 'nio'

module Centrifuge
  module Exec
    class << self
      def exec(command, options)
        default_options = {
          capture: false,
          indent: '>>> ',
          chdir: Dir.pwd,
          timeout: 1200 * 60,
          print: true
        }
        opts = default_options.merge(options)

        result = OpenStruct.new
        result.retcode = nil
        result.output = nil
        result.success = false
        class << result
          def success?
            self.success
          end
        end

        Centrifuge.logger.debug "#{opts[:indent]}#{command}"
        Dir.chdir(opts[:chdir]) do
          status = nil
          if opts[:capture]
            output, status = Open3.capture2(command)
            Centrifuge.logger.debug "Captured output: #{output}" if opts[:print]
            result.output = output
            result.retcode = status.exitstatus
          else
            status = streaming(command, opts)
            result.retcode = status.exitstatus
          end
          result.success = status.success?
        end
        result
      end

      private

      def streaming(command, opts)
        block_size = 4096

        selector = NIO::Selector.new

        stdin, stdout, stderr, thread = Open3.popen3(command)

        monitor_stdout = selector.register(stdout, :r)
        monitor_stderr = selector.register(stderr, :r)

        monitor_stdout.value = proc {
          line = monitor_stdout.io.read_nonblock(block_size)
          Centrifuge.logger.info "#{opts[:indent]}#{line.rstrip}" if opts[:print]
        }
        monitor_stderr.value = proc {
          line = monitor_stderr.io.read_nonblock(block_size)
          Centrifuge.logger.info "#{opts[:indent]}#{line.rstrip}" if opts[:print]
        }

        loop do
          begin
            ready = selector.select(opts[:timeout])
            raise "Command timeout of #{opts[:timeout]}" if ready.nil?

            ready.each { |m| m.value.call }
          rescue EOFError
            break
          end
        end

        thread.value
      end
    end
  end
end
