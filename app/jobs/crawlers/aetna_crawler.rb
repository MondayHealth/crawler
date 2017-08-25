require_relative 'base'

module Jobs
  module Crawlers
    class AetnaCrawler < Base
      @queue = :crawler_aetna

      def self.perform(plan_id, url, options={})
        @wait = Selenium::WebDriver::Wait.new(timeout: 20) # seconds
        @ssdb = SSDB.new url: "ssdb://#{ENV['SSDB_HOST']}:#{ENV['SSDB_PORT']}"

        # If the page has already been fetched, block unless we're force refreshing
        unless options[:force_refresh]
          return if @ssdb.exists(url)
        end

        page_source = nil
        Headless.ly do
          @driver = Selenium::WebDriver.for :firefox
          @driver.navigate.to url
          @wait.until do
            begin
              @driver.find_element(id: "pageNumbers")
              true
            rescue Selenium::WebDriver::Error::ServerError => e
              unless e.message =~ /404/
                raise e
              end
            end
          end
          # we need to strip out tabs and newlines here since they mess with ssdb-rb's GET method
          # might as well get rid of extra space characters while we're at it
          page_source = @driver.page_source.gsub("\n", " ").gsub("\t", " ").gsub(/\s+/, " ")
        end
        @ssdb.set(url, page_source)
        STDOUT.puts("Enqueueing AetnaScraper with [#{plan_id}, #{url}]")
        Resque.push('scraper_aetna', :class => 'Jobs::Scrapers::AetnaScraper', :args => [plan_id, url])
      end
    end
  end
end