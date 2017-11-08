module Jobs
  module Crawlers
    module Detail
      class PsychologyTodayDetailCrawler < Base

        @queue = :crawler_psychology_today_detail

        def self.perform detail_url, options={}
          @ssdb = SSDB.new url: "ssdb://#{ENV['SSDB_HOST']}:#{ENV['SSDB_PORT']}"
          cache_key = detail_url

          # If the page has already been fetched, block unless we're force refreshing
          unless options["force_refresh"]
            if @ssdb.exists(cache_key)
              schedule_scrape(cache_key)
              return
            end
          end

          response = RestClient::Request.execute(method: :get, url: detail_url, proxy: "http://#{ENV['POLIPO_PROXY']}")
          page_source = response.body

          @ssdb.set(cache_key, sanitize_for_ssdb(page_source))

          schedule_scrape(cache_key)
        end

        def self.schedule_scrape cache_key
          STDOUT.puts("Enqueueing PsychologyTodayScraper with #{cache_key}")
          Resque.push('scraper_psychology_today', :class => 'Jobs::Scrapers::PsychologyTodayScraper', :args => [cache_key])
        end
      end
    end
  end
end