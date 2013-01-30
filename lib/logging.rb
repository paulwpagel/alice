require 'log4r'

module Rinda
  def self.create_logger(name, file)
    logger = Log4r::Logger.new(name)
    logger.level = Log4r::DEBUG
    formatter = Log4r::PatternFormatter.new(:pattern => "[%l] %c %d :: %m")
    if(defined?(RAILS_ENV) and RAILS_ENV != 'development')
      outputter = Log4r::RollingFileOutputter.new(name, :filename => file, :maxsize => 1024000, :trunc => false)
    else
      outputter = Log4r::FileOutputter.new(name, :filename => file, :trunc => false)
    end
    outputter.formatter = formatter
    logger.add(name)
  
    return logger
  end
end
