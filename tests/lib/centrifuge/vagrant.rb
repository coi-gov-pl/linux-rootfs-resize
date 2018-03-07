module Centrifuge
  module Vagrant
    require 'centrifuge/vagrant/provider'

    class << self
      def new(box)
        Centrifuge::Vagrant::Provider.new(box)
      end
    end
  end
end
