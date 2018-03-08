require 'logger'

module Centrifuge
  class << self
    begin
      logger = Logger.new(STDERR)
      loglevel = ENV.fetch('CENTRIFUGE_LOG_LEVEL', 'INFO')
      logger.level = Logger::Severity.const_get(loglevel)
      logger.formatter = proc do |severity, datetime, progname, msg|
        date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
        loglevel = severity.rjust(5,' ')
        "#{date_format} #{loglevel} #{msg}\n"
      end
      @@logger = logger
    end

    def logger
      @@logger
    end

  end
end
