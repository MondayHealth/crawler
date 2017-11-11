require_relative 'base'

module Monday
  module Strategies
    module Pagination
      class Empire < Base

        @queue_name = 'crawler_empire'
        @job_class = 'Jobs::Crawlers::EmpireCrawler'

        DISTANCE = 10
        PER_PAGE = 100
        BASE_QUERY_STRING = '&alphaPrefix=&bcbsaProductId/results/acceptingNewPatients=false&alphaPrefix=&boardCertified=&hasExtendedHours=false&gender=&isEligiblePCP=false&maxLatitude=&maxLongitude=&minLatitude=&minLongitude=&name=&patientAgeRestriction=&patientGenderRestriction=&providerCategory=P&qualityRecognitions=&searchType=advanced&sort=DEFAULT&location=location=New%2520York%252C%2520NY'

        # Each provider type maps to an optional list of specialty IDs, 
        # e.g. "Physicians specializing in Anxiety"
        PROVIDER_TYPES_AND_SPECIALTY_IDS = {
          "CNSLR" => [],
          "PHYSC" => ["8183575", "9395761", "8278232", "2791940", "9783466", "8433601"],
          "PHYAST" => ["NC75052", "NC74907", "LC70919"]
        }

        def enqueue_all plan
          PROVIDER_TYPES_AND_SPECIALTY_IDS.each_pair do |provider_type, specialty_ids|
            url = plan.url + BASE_QUERY_STRING
            url += "&productCode=#{plan.original_code}"
            url += "&size=#{PER_PAGE}"
            url += "&radius=#{DISTANCE}"
            url += "&providerType=#{provider_type}"
            specialty_ids.each do |specialty_id|
              url += "&specialties=#{specialty_id}"
            end
            url += "&page=1"
            record_limit = fetch_record_limit(url)

            current_url = url

            while !self.hit_record_limit? current_url, record_limit
              yield current_url
              current_url = self.next_page(current_url)
            end
          end
        end

        def next_page url
          url.sub(/page=([0-9]*)/) { "page=#{Regexp.last_match[1].to_i + 1}" }
        end

        def hit_record_limit? url, limit
          page = 0
          url.scan(/page=([0-9]*)/) do 
            page = Regexp.last_match[1].to_i
          end
          page * PER_PAGE > limit + 1
        end

        def fetch_record_limit url
          puts "Fetching record limit from #{url}"
          @wait = Selenium::WebDriver::Wait.new(timeout: 60) # seconds
          Headless.ly do
            results_count_string = nil

            caps = Selenium::WebDriver::Remote::Capabilities.firefox
            caps['acceptInsecureCerts'] = true

            @driver = Selenium::WebDriver.for :firefox, desired_capabilities: caps
            begin
              @driver.navigate.to url
              @wait.until do
                begin
                  results_count = @driver.find_element(css: "div[data-test='results-count-greater-than-one']")
                  results_count_string = results_count.text
                rescue Selenium::WebDriver::Error::NoSuchElementError => e
                  # Are we on an empty results page?
                  @driver.find_element(id: "results-container")
                end
                true
              end
              @driver.quit
            rescue Exception => e
              # Make sure we quit the browser even if we run into an exception we didn't anticipate
              @driver.quit
              raise e
            end

            if results_count_string
              results_count_match = results_count_string.match(/\s+of\s+([0-9,]+)\s+results/)
              return results_count_match[1].gsub(',', '').to_i
            else
              return 0
            end
          end
        end

      end
    end
  end
end