require 'centrifuge/hddresizer/vboxmanage'

module Centrifuge
  module HddResizer
    class << self
      def new(vagrant, machinename = 'default')
        Centrifuge::HddResizer::VBoxManage.new(vagrant, machinename)
      end
    end
  end
end
