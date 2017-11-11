require_relative 'base'

module Jobs
  module Crawlers
    class EmpireCrawler < Base
      @queue = :crawler_empire

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
          caps = Selenium::WebDriver::Remote::Capabilities.firefox
          caps['acceptInsecureCerts'] = true

          @driver = Selenium::WebDriver.for :firefox, desired_capabilities: caps
          begin
            @driver.navigate.to url
            @wait.until do
              @driver.find_element(css: "div[data-test='results-count-greater-than-one']")
            end
            page_source = @driver.page_source
            self.ssdb.set(url, sanitize_for_ssdb(page_source))

            schedule_scrape(plan_id, url)

            @driver.quit
          rescue Exception => e
            # Make sure we quit the browser even if we run into an exception we didn't anticipate
            @driver.quit
            raise e
          end
        end
      end

      def self.schedule_scrape plan_id, url
        STDOUT.puts("Enqueueing EmpireScraper with [#{plan_id}, #{url}]")
        Resque.push('scraper_empire', :class => 'Jobs::Scrapers::EmpireScraper', :args => [plan_id, url])
      end

    end
  end
end