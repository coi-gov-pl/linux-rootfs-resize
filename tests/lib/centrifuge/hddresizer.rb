require 'centrifuge/hddresizer/vboxmanage'

module Centrifuge
  module HddResizer
    class << self
      def new(vagrant)
        Centrifuge::HddResizer::VBoxManage.new(vagrant)
      end
    end
  end
end
