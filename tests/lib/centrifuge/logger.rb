module Centrifuge
  class << self
    require 'logger'

    begin
      @@logger = Logger.new(STDERR)
      loglevel = ENV.fetch('CENTRIFUGE_LOG_LEVEL', 'INFO')
      @@logger.level = Logger::Severity.const_get(loglevel)
    end

    def logger
      @@logger
    end

  end
end
