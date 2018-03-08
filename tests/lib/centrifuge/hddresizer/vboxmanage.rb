require 'centrifuge/cmdexec'
require 'inifile'

module Centrifuge
  module HddResizer
    module Executor
      def execute(command, options = {})
        indent = 'local'.rjust(7,' ')
        defaults = { indent: "[#{indent}] " }
        result = Centrifuge::Exec.exec(command, defaults.merge(options))
        raise "Command failed: #{result.output}" unless result.success?
        result
      end
    end

    class VBoxManage
      include Centrifuge::HddResizer::Executor

      def initialize(vagrant)
        @vagrant = vagrant
        @vboxmachine = nil
      end

      def resize(spec)
        defaults = {
          size: 10,
          unit: :GiB,
          controller: 'SATA Controller-0-0'
        }
        possible_units = [:GiB, :GB, :MiB, :MB]
        spec = defaults.merge(spec)
        raise "Illegal unit passed, possible values are #{possible_units}" unless possible_units.include? spec[:unit]

        @vboxmachine = Centrifuge::HddResizer::VBoxMachine.get(@vagrant.workdir)

        Centrifuge.logger.debug "Resizing VM HDD to #{spec}"

        hddfile = hdd_location(spec)
        Centrifuge.logger.debug "HDD to resize: #{hddfile}"

        resize_hddfile(hddfile, spec)
      end

      private

      def resize_hddfile(hddfile, spec)
        imagetype = hddfile.extname.gsub(/^\./, '').to_sym
        case imagetype
        when :vmdk
          resize_vmdk(hddfile, spec)
        when :vdi
          resize_vdi(hddfile, spec)
        else
          raise "Only VMDK and VDI are supported, given: #{imagetype}"
        end
      end

      def attach_hdd(hddfile)
        execute "VBoxManage storageattach '#{@vboxmachine.machineid}' --storagectl 'SATA Controller' --port 0 --device 0 --type hdd --medium '#{hddfile}'"
      end

      def deletehdd(hddfile)
        execute "VBoxManage closemedium '#{hddfile}' --delete"
      end

      def resize_vmdk(vmdk, spec)
        Centrifuge.logger.debug "Performing resize of VMDK image: #{vmdk}"
        tmpfile = Tempfile.new(['disk-', '.vdi'])
        vdi = Pathname.new(tmpfile)
        tmpfile.unlink
        begin
          convert_vmdk_to_vdi(vmdk, vdi)
          attach_hdd(vdi)
          resize_vdi(vdi, spec)
          convert_vdi_to_vmdk(vdi, vmdk)
          attach_hdd(vmdk)
        ensure
          tmpfile.unlink
        end
      end

      def convert_vmdk_to_vdi(vmdk, vdi, clobber = true)
        opts = [
          '--format VDI',
          '--variant Standard'
        ]
        if File.file? vdi
          raise "Target: #{vdi} exists and clobber is false" unless clobber
          deletehdd vdi if clobber
        end
        opts = opts.join ' '
        execute "VBoxManage clonemedium disk '#{vmdk}' '#{vdi}' #{opts}"
      end

      def convert_vdi_to_vmdk(vdi, vmdk, clobber = true)
        opts = [
          '--format VMDK',
          '--variant Standard'
        ]
        if File.file? vmdk
          raise "Target: #{vmdk} exists and clobber is false" unless clobber
          deletehdd vmdk if clobber
        end
        opts = opts.join ' '
        execute "VBoxManage clonemedium disk '#{vdi}' '#{vmdk}' #{opts}"
      end

      def resize_vdi(vdi, spec)
        Centrifuge.logger.debug "Performing resize of VDI image: #{vdi}"
        size_mb = calculate_size_in_megabytes(spec)
        execute "VBoxManage modifyhd '#{vdi}' --resize #{size_mb}"
      end

      def calculate_size_in_megabytes(spec)
        size = spec[:size]
        unit = spec[:unit]
        multiplayer = {
          GiB: 1024,
          GB: 1000,
          MiB: 1,
          MB: 1
        }[unit]
        size * multiplayer
      end

      def hdd_location(spec)
        file = @vboxmachine.vminfo spec[:controller]
        raise "HDD file is not readable: #{file}" unless File.readable?(file)
        Pathname.new(file)
      end
    end

    class VBoxMachine

      attr_reader :machineid

      def initialize(machineid, vminfo)
        @machineid = machineid
        @vminfo = vminfo
      end

      def vminfo(setting)
        @vminfo[quote_vminfo(setting)]
      end

      private def quote_vminfo(value)
        stringified = value.to_s
        if stringified.include? ' '
          stringified.inspect
        else
          stringified
        end
      end

      class << self
        include Centrifuge::HddResizer::Executor

        def get(workdir)
          machineid = File.read("#{workdir}/.vagrant/machines/default/virtualbox/id")
          vminfo = vminfo_for machineid
          Centrifuge::HddResizer::VBoxMachine.new(machineid, vminfo)
        end

        private

        def vminfo_for(machineid)
          command = "VBoxManage showvminfo #{machineid} --machinereadable"
          result = execute command, capture: true, print: false
          parse_vminfo(result.output)['global']
        end

        def parse_vminfo(output)
          Tempfile.open('VBoxManage-vminfo') do |file|
            file.write(output)
            file.flush
            IniFile.load(file)
          end
        end
      end
    end
  end
end
