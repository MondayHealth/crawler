require_relative 'base'

module Jobs
  module Crawlers
    class OscarCrawler < Base
      @queue = :crawler_oscar

      def self.perform(plan_id, url, options={})
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
          page_source = RestClient.get(url)
        end

        self.ssdb.set(cache_key, sanitize_for_ssdb(page_source))

        schedule_scrape(plan_id, url)
      end

      def self.schedule_scrape plan_id, url
        STDOUT.puts("Enqueueing OscarScraper with [#{plan_id}, #{url}]")
        Resque.push('scraper_oscar', :class => 'Jobs::Scrapers::OscarScraper', :args => [plan_id, url])
      end
    end
  end
end