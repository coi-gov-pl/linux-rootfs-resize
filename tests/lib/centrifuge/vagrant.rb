require 'centrifuge/vagrant/provider'

module Centrifuge
  module Vagrant
    class << self
      def new(box)
        Centrifuge::Vagrant::Provider.new(box)
      end
    end
  end
end
