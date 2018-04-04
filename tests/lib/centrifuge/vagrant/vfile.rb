require 'erb'

module Centrifuge
  module Vagrant
    class Vfile

      def initialize(box)
        @box = box
        @workdir = nil
      end

      def workdir
        if @workdir.nil?
          slugged = @box.gsub(/\//, '-')
          @workdir = Dir.mktmpdir(['centrifuge', slugged])
        end
        @workdir
      end

      def create
        Centrifuge.logger.debug "Creating Vagrantfile for #{@box}"

        vfile_location = "#{workdir}/Vagrantfile"
        open(vfile_location, "w") do |targetfile|
          source = compile
          Centrifuge.logger.debug "Vagrantfile location: #{vfile_location}"
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
        currdir = File.dirname(__FILE__)
        template = ERB.new(File.read("#{currdir}/vfile.erb"))
        template.result(binding)
      end
    end
  end
end
