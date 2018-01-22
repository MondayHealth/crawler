require_relative 'base'

module Jobs
  module Crawlers
    class OxfordCrawler < Base

      class MissingSessionError < Exception; end
      class NoJSONError < Exception; end
      
      @queue = :crawler_oxford

      def self.perform(plan_id, url, options={})
        if options["session_key"].nil? || options["session_id"].nil?
          raise MissingSessionError.new("Missing session info for URL #{url}")
        end
        cache_key = url
        
        # If the page has already been fetched, block unless we're force refreshing
        unless options[:force_refresh]
          if self.ssdb.exists(cache_key)
            schedule_scrape(plan_id, url)
            return
          end
        end

        page_source = nil
        with_retries(max_tries: 5, rescue: RestClient::Exception) do
          headers = {}
          headers["cookie"] = "#{options["session_key"]}=#{options["session_id"]}"
          headers["referer"] = "https://connect.werally.com/"
          page_source = RestClient.get(url, headers)
        end

        # scraper expects JSON—if we get HTML (e.g. if banned) fail here first
        begin 
          json = JSON.parse(page_source)
        rescue JSON::ParserError
          raise NoJSONError.new("Unexpected page response (not JSON) from #{url}")
        end

        self.ssdb.set(cache_key, sanitize_for_ssdb(page_source))

        schedule_scrape(plan_id, url)
      end

      def self.schedule_scrape plan_id, url
        STDOUT.puts("Enqueueing OscarScraper with [#{plan_id}, #{url}]")
        Resque.push('scraper_oxford', :class => 'Jobs::Scrapers::OxfordScraper', :args => [plan_id, url])
      end
    end
  end
end