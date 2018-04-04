module Centrifuge
  PROJECT_DIR = File.dirname(File.dirname(File.dirname(__FILE__)))
  
  require 'centrifuge/logger'
  require 'centrifuge/vagrant'
  require 'centrifuge/runner'
end
