require_relative 'defaults'

require 'otr-activerecord'

OTR::ActiveRecord.configure_from_file! "config/database.yml"

require 'redis-queue'

module Monday
  class Queue
    def self.queue
      @redis ||= Redis.new(:host => ENV['REDIS_HOST'], :port => ENV['REDIS_PORT'], :password => ENV['REDIS_PASS']) 
      @queue ||= Redis::Queue.new('q_crawler_urls','bp_q_crawler_urls',  :redis => @redis)
    end
  end
end

Dir[File.join("app", "**/*.rb")].each do |file_path|
  require_relative file_path
end