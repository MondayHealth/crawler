require_relative 'base'

module Jobs
  module Crawlers
    class AetnaCrawler < Base
      @queue = :crawler_aetna

      def self.perform(plan_id, url, options={})
        @wait = Selenium::WebDriver::Wait.new(timeout: 20) # seconds

        # If the page has already been fetched, block unless we're force refreshing
        unless options[:force_refresh]
          if self.ssdb.exists(url)
            schedule_scrape(plan_id, url)
            return
          end
        end

        page_source = nil
        Headless.ly do
          @driver = Selenium::WebDriver.for_firefox_with_proxy
          begin
            @driver.navigate.to "http://www.aetna.com/dse/search?site_id=dse&langPref=en"
            @wait.until do
              @driver.find_element(id: "searchType")
              sleep 2
            end
            @driver.execute_script("window.open()")
            @driver.switch_to.window(@driver.window_handles.last)
            @driver.navigate.to url
            @wait.until do
              begin
                # Did we find any results?
                @driver.find_element(id: "pageNumbers")
                true
              rescue Selenium::WebDriver::Error::ServerError => e
                unless e.message =~ /404/
                  raise e
                end
              rescue Selenium::WebDriver::Error::NoSuchElementError => e
                # Are we on an empty results page?
                @driver.find_element(id: "noResultsSection")
                true
              end
            end

            begin
              # Did we find any results?
              @driver.find_element(id: "pageNumbers")

              # we need to strip out tabs and newlines here since they mess with ssdb-rb's GET method
              # might as well get rid of extra space characters while we're at it
              page_source = @driver.page_source
              self.ssdb.set(url, sanitize_for_ssdb(page_source))

              schedule_scrape(plan_id, url)
            rescue Selenium::WebDriver::Error::NoSuchElementError => e
              STDOUT.puts("No results found for [#{plan_id}, #{url}]")
            end
            @driver.quit
          rescue Exception => e
            # Make sure we quit the browser even if we run into an exception we didn't anticipate
            puts @driver.page_source
            @driver.quit
            raise e
          end
        end
      end
      
      def self.schedule_scrape plan_id, url
        STDOUT.puts("Enqueueing AetnaScraper with [#{plan_id}, #{url}]")
        Resque.push('scraper_aetna', :class => 'Jobs::Scrapers::AetnaScraper', :args => [plan_id, url])
      end
    end
  end
end