module Jobs
  module Crawlers
    module Detail
      class GoodTherapyDetailCrawler < Base
        URL = "https://www.goodtherapy.org/therapists/profile/<URL_SLUG>"

        @queue = :crawler_good_therapy_detail

        def self.perform url_slug, options={}
          @ssdb = SSDB.new url: "ssdb://#{ENV['SSDB_HOST']}:#{ENV['SSDB_PORT']}"
          detail_url = URL.sub("<URL_SLUG>", url_slug)
          cache_key = detail_url

          # If the page has already been fetched, block unless we're force refreshing
          unless options["force_refresh"]
            if @ssdb.exists(cache_key)
              schedule_scrape(cache_key)
              return
            end
          end

          response = RestClient.get(detail_url)
          page_source = response.body

          @ssdb.set(cache_key, sanitize_for_ssdb(page_source))

          schedule_scrape(cache_key)
        end

        def self.schedule_scrape cache_key
          STDOUT.puts("Enqueueing GoodTherapyScraper with #{cache_key}")
          Resque.push('scraper_good_therapy', :class => 'Jobs::Scrapers::GoodTherapyScraper', :args => [cache_key])
        end
      end
    end
  end
end