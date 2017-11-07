require_relative 'base'

module Jobs
  module Crawlers
    class PsychologyTodayCrawler < Base
      URL = 'https://therapists.psychologytoday.com/rms/'
      PER_PAGE = 20

      # currently there are a little more than 7000 therapists in NY, and no
      # way to get the totals from the page, so we'll go up to 8k for now to
      # account for some expansion and accept that we'll waste some requests
      RECORD_LIMIT = 8000 

      @queue = :crawler_psychology_today

      def self.enqueue_all options={}
        @wait = Selenium::WebDriver::Wait.new(timeout: 20) # seconds
        Headless.ly do
          @driver = Selenium::WebDriver.for :firefox
          begin
            @driver.navigate.to URL
            search_field = nil
            @wait.until do
              search_field = @driver.find_element(id: "searchField")
              search_field.enabled? && search_field.displayed?
            end
            search_field.click

            autosuggest_search_field = nil
            @wait.until do
              autosuggest_search_field = @driver.find_element(id: "autosuggestSearchInput")
              autosuggest_search_field.enabled? && autosuggest_search_field.displayed?
            end
            autosuggest_search_field.send_key '1'
            autosuggest_search_field.send_key '0'
            autosuggest_search_field.send_key '1'
            autosuggest_search_field.send_key '0'
            autosuggest_search_field.send_key '4'

            button = @driver.find_element(id: "autosuggestSearchButton")
            button.click

            pagination_link = nil
            @wait.until do
              pagination_link = @driver.find_element(css: ".endresults-right a")
            end
            current_url = pagination_link.attribute("href")
            current_url.sub(/rec_next=([0-9]*)/, "rec_next=1")

            options = {}
            options["cookie"] = self.cookie_string

            (RECORD_LIMIT/PER_PAGE).times do |page|
              STDOUT.puts("Enqueueing Jobs::Crawlers::PsychologyTodayCrawler with [#{current_url}, #{options.inspect}]")
              Resque.enqueue(Jobs::Crawlers::PsychologyTodayCrawler, current_url, options)
              current_url.sub(/page_start_idx=([0-9]*)/) { "page_start_idx=#{Regexp.last_match[1].to_i + PER_PAGE}" }
            end

            @driver.quit
          rescue Exception => e
            # Make sure we quit the browser even if we run into an exception we didn't anticipate
            STDOUT.puts @driver.page_source
            @driver.quit
            raise e  
          end
        end
      end

      def self.perform url, options={}
        cache_key = url

        # If the page has already been fetched, block unless we're force refreshing
        unless options[:force_refresh]
          if self.ssdb.exists(cache_key)
            schedule_detail_crawl(cache_key)
            return
          end
        end

        headers = { "User-Agent": USER_AGENT_STRING, "Cookie": options["cookie"] }
        response = RestClient.get(url, headers)
        doc = Nokogiri::HTML.parse(response.body)
        doc.css('.result-row').each do |div|
          profile_url = div['data-profile-url']
          schedule_detail_crawl(profile_url)
        end
      end

      def self.schedule_detail_crawl url
        Resque.enqueue(Jobs::Crawlers::Detail::PsychologyTodayDetailCrawler, url)
      end

    end
  end
end