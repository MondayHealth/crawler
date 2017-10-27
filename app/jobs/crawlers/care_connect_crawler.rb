require_relative 'base'
require 'uri'

module Jobs
  module Crawlers
    class CareConnectCrawler < Base
      USER_AGENT_STRING = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36'

      @queue = :crawler_care_connect

      def self.perform(plan_id, url, options={})
        # convert the data JSON to a URL query string for cache keys so they're
        # easier to read, copy/paste etc. when debugging
        cache_key = url + "?" + URI.encode_www_form(options["data"])
        
        # If the page has already been fetched, block unless we're force refreshing
        unless options[:force_refresh]
          if self.ssdb.exists(cache_key)
            schedule_scrape(plan_id, cache_key)
            return
          end
        end

        page_source = nil
        with_retries(max_tries: 5, rescue: RestClient::Exception) do
          headers = {}
          headers["Cookie"] = options["cookie"]
          headers["User-Agent"] = USER_AGENT_STRING
          page_source = RestClient.post(url, options["data"].to_json, headers.merge({content_type: :json, accept: :json})) do |response, request, result, &block|
            if [301, 302, 307].include? response.code
              response.follow_redirection(request, result, &block)
            else
              response.return!(request, result, &block)
            end
          end
        end

        self.ssdb.set(cache_key, sanitize_for_ssdb(page_source))

        schedule_scrape(plan_id, cache_key)
      end

      def self.schedule_scrape plan_id, cache_key
        STDOUT.puts("Enqueueing CareConnectScraper with [#{plan_id}, #{cache_key}]")
        Resque.push('scraper_care_connect', :class => 'Jobs::Scrapers::CareConnectScraper', :args => [plan_id, cache_key])
      end
    end
  end
end