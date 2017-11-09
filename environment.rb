require 'headless'
require 'selenium-webdriver'
require 'ssdb'
require 'json'

require_relative 'defaults'

require 'otr-activerecord'
require 'rest-client'
require 'curb'
require 'nokogiri'
require 'retries'

OTR::ActiveRecord.configure_from_file! "config/database.yml"

Dir[File.join("config/initializers", "*.rb")].each do |file_path|
  require_relative file_path
end

Dir[File.join("app", "**/*.rb")].each do |file_path|
  require_relative file_path
end

if ENV["SELENIUM_DEBUG"]
  Selenium::WebDriver.logger.level = :debug
end
