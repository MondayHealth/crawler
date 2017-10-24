require_relative 'base'
require 'uri'

module Monday
  module Strategies
    module Pagination
      class Cigna < Base
        PER_PAGE = 10
        QUERY_STRING = "?searchCategoryCode=HSC01&consumerCode=HDC001&geolocation.city=New+York&geolocation.stateCode=NY&geolocation.formattedAddress=New+York%2C+NY%2C+USA&geolocation.latitude=40.7127753&geolocation.longitude=-74.0059728&geoLocation=&viewtype=list&action=searchProviders&searchLocation=New+York%2C+NY%2C+USA&medicalProductCode=<PRODUCT_CODE>"
        PRODUCT_CODES = {
          "CIGNA HealthCare of New York, Inc." => "HMONY013",
          "PPO, Choice Fund PPO" => "PPO",
          "Open Access Plus, OA Plus, Choice Fund OA Plus" => "OAP"
        }

        @queue_name = 'crawler_cigna'
        @job_class = 'Jobs::Crawlers::CignaCrawler'

        def enqueue_all plan
          @wait = Selenium::WebDriver::Wait.new(timeout: 20) # seconds
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
            search_url = host + action + QUERY_STRING.sub("<PRODUCT_CODE>", product_code)

            @driver.navigate.to search_url
            scroll_container = nil
            @wait.until do
              scroll_container = @driver.find_element(css: ".nfinite-scroll-container")
            end
            search_url = scroll_container.attribute('data-nfinite-url')
            other_params = scroll_container.attribute('data-nfinite-other-params') + "&offset=0"
            record_limit = scroll_container.attribute('data-nfinite-total').to_i

            @cookies = @driver.manage.all_cookies
            cookie_string = @cookies.map do |cookie|
              "#{cookie[:name]}=#{cookie[:value]}"
            end.join("; ")
            options = {}
            options["cookie"] = cookie_string

            current_url = host + search_url + "?" + other_params
            while !self.hit_record_limit? current_url, record_limit
              yield current_url, options
              current_url = self.next_page(current_url)
            end
          end
        end

        def next_page url
          url.sub(/offset=([0-9]*)/) { "offset=#{Regexp.last_match[1].to_i + PER_PAGE}" }
        end

        def hit_record_limit? url, limit
          page = 0
          url.scan(/offset=([0-9]*)/) do 
            page = Regexp.last_match[1].to_i
          end
          page + PER_PAGE > limit
        end

      end
    end
  end
end
