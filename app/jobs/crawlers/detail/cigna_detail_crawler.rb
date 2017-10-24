module Jobs
  module Crawlers
    module Detail
      class CignaDetailCrawler < Base

        class MissingSessionError < Exception; end
        
        @queue = :crawler_cigna_detail

        def self.perform(plan_id, url, options={})
          if options["cookie"].nil?
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
            headers["cookie"] = options["cookie"]
            page_source = RestClient.get(url, headers)
          end

          self.ssdb.set(cache_key, sanitize_for_ssdb(page_source))

          schedule_scrape(plan_id, url)
        end

        def self.schedule_scrape plan_id, url
          STDOUT.puts("Enqueueing CignaScraper with [#{plan_id}, #{url}]")
          Resque.push('scraper_cigna', :class => 'Jobs::Scrapers::CignaScraper', :args => [plan_id, url])
        end
      end
    end
  end
end

