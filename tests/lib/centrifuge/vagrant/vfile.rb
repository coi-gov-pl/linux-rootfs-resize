module Centrifuge
  module Vagrant
    class Vfile
      attr_reader :workdir

      def initialize(box)
        @box = box
      end

      def create
        Centrifuge.logger.debug "Creating Vagrantfile for #{@box}"
        slugged = @box.gsub(/\//, '-')
        @workdir = Dir.mktmpdir(['centrifuge', slugged])
        open("#{@workdir}/Vagrantfile", "w") do |targetfile|
          source = compile
          Centrifuge.logger.debug "Vagrantfile source: \n#{source}"
          targetfile.write(source)
        end
      end

      def destroy
        Centrifuge.logger.debug "Removing Vagrantfile for #{@box}"
        FileUtils.remove_entry(@workdir) unless @workdir.nil?
      end

      def to_s
        "Vagrantfile at #{@workdir}"
      end

      private

      def compile
        require 'erb'

        currdir = File.dirname(__FILE__)
        template = ERB.new(File.read("#{currdir}/vfile.erb"))
        template.result(binding)
      end
    end
  end
end
