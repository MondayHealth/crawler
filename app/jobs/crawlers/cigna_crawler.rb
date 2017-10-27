require_relative 'base'

module Jobs
  module Crawlers
    class CignaCrawler < Base
      PER_PAGE = 10
      QUERY_STRING = "?searchCategoryCode=HSC01&consumerCode=HDC001&geolocation.city=New+York&geolocation.stateCode=NY&geolocation.formattedAddress=New+York%2C+NY%2C+USA&geolocation.latitude=40.7127753&geolocation.longitude=-74.0059728&geoLocation=&viewtype=list&action=searchProviders&searchLocation=New+York%2C+NY%2C+USA&searchTermSource=typeAheadSuggestion&typeaheadDataGroupCode=HTAG08&typeaheadSuggestionCode=<SUGGESTION_CODE>&medicalProductCode=<PRODUCT_CODE>"
      PRODUCT_CODES = {
        "CIGNA HealthCare of New York, Inc." => "HMONY013",
        "PPO, Choice Fund PPO" => "PPO",
        "Open Access Plus, OA Plus, Choice Fund OA Plus" => "OAP"
      }

      @queue = :crawler_cigna

      def self.perform(plan_id, url, options={})
        plan = Plan.find(plan_id)
        specialty_code = options["specialty_code"]

        @wait = Selenium::WebDriver::Wait.new(timeout: 60, ignore: Selenium::WebDriver::Error::NoSuchElementError)
        page_source = nil
        Headless.ly do
          @driver = Selenium::WebDriver.for :firefox
          @driver.navigate.to plan.url
          @wait.until do
            location_field = @driver.find_element(id: "searchLocation")
          end

          form = @driver.find_element(id: "searchForm")
          action = form.attribute('action')

          uri = URI.parse(plan.url)
          host = plan.url.sub(uri.path, '')

          product_code = PRODUCT_CODES[plan.name]

          search_url = host + action + QUERY_STRING.sub("<PRODUCT_CODE>", product_code).sub("<SUGGESTION_CODE>", specialty_code)

          @driver.navigate.to search_url
          scroll_container = nil
          @wait.until do
            sleep 2 # for some reason, this is 404-ing only on the server unless we sleep for a second
            begin
              scroll_container = @driver.find_element(css: ".nfinite-scroll-container")
            rescue Selenium::WebDriver::Error::NoSuchElementError => e
              # Are we on an empty results page?
              @driver.find_element(xpath: "//p[contains(text(), 'found no results')]")
              true
            end
          end

          if scroll_container.nil?
            return # no results found
          end

          search_url = scroll_container.attribute('data-nfinite-url')
          other_params = scroll_container.attribute('data-nfinite-other-params') + "&offset=0"
          record_limit = scroll_container.attribute('data-nfinite-total').to_i

          options = {}
          options["cookie"] = self.cookie_string

          current_url = host + search_url + "?" + other_params
          while !self.hit_record_limit? current_url, record_limit
            Resque.enqueue(Jobs::Crawlers::Detail::CignaDetailCrawler, plan_id, current_url, options)
            current_url = self.next_page(current_url)
          end
        end
      end

      def self.next_page url
        url.sub(/offset=([0-9]*)/) { "offset=#{Regexp.last_match[1].to_i + PER_PAGE}" }
      end

      def self.hit_record_limit? url, limit
        page = 0
        url.scan(/offset=([0-9]*)/) do 
          page = Regexp.last_match[1].to_i
        end
        page + PER_PAGE > limit
      end
    end
  end
end

