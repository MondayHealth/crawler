require_relative 'base'

module Jobs
  module Crawlers
    class EmblemCrawler < Base
      @queue = :crawler_emblem

      class UnsuccessfulLoadError < StandardError; end

      def self.perform(plan_id, url, options={})
        # tack the POST data onto the URL as a query param to make cache key unique
        cache_key = url + "?" + options["body"]
        
        # If the page has already been fetched, block unless we're force refreshing
        unless options[:force_refresh]
          if self.ssdb.exists(cache_key)
            schedule_scrape(plan_id, cache_key)
            return
          end
        end

        page_source = nil
        with_retries(max_tries: 5, rescue: Curl::Err::CurlError) do
          http_referer = "https://www.valueoptions.com/referralconnect/providerSearch.do?nextpage=nextpage"
          response = Curl::Easy.http_post(url, options["body"]) do |curl|
            curl.headers['Cookie'] = options['cookie']
            curl.headers['Referer'] = http_referer
          end
          unless response.response_code == 200
            raise UnsuccessfulLoadError.new("Unsuccessful Load (#{response.response_code})")
          end
          page_source = response.body_str
        end

        self.ssdb.set(cache_key, sanitize_for_ssdb(page_source))

        schedule_scrape(plan_id, cache_key)
      end

      def self.schedule_scrape plan_id, cache_key
        STDOUT.puts("Enqueueing EmblemScraper with [#{plan_id}, #{cache_key}]")
        Resque.push('scraper_emblem', :class => 'Jobs::Scrapers::EmblemScraper', :args => [plan_id, cache_key])
      end
    end
  end
end