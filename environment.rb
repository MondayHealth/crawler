module Monday
  class Queue
    def self.queue
      @redis ||= Redis.new(:host => ENV['REDIS_HOST'], :port => ENV['REDIS_PORT'], :password => ENV['REDIS_PASS']) 
      @queue ||= Redis::Queue.new('q_crawler_urls','bp_q_crawler_urls',  :redis => @redis)
    end
  end
end