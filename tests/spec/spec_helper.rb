require 'rspec/its'
require 'centrifuge'
require 'constants'
require 'shared_examples'

def gem_present(name)
  !Bundler.rubygems.find_name(name).empty?
end

require 'pry' if gem_present 'pry'

RSpec.configure do |c|

  c.mock_with :rspec do |mock|
    mock.syntax = %i[expect]
  end

  # Readable test descriptions
  c.formatter = :documentation
end
