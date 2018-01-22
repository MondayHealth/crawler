require_relative 'base'

module Monday
  module Strategies
    module Pagination
      class Oxford < Base
        PER_PAGE = 10

        SPECIALTIES = {
          "Neurology and Psychiatry": "specialty=170",
          "Psychology - Clinical": "specialty=337",
          "Licensed Professional Counselor": "specialty=321",
          "Social Work": "specialty=341"
        }

        UNITED_COMMERCIAL_SPECIALTIES = {
          "Psychiatrist (Physician)": "specialtyCategory=11",
          "Psychologist": "specialtyCategory=12",
          "Master Level Clinician": "specialtyCategory=13",
          "Nurse Masters Level": "specialtyCategory=14",
          "Telemental Health Providers": "areaOfExpertise=28&specialtyCategory=15"
        }

        ZIP = "10104"
        DISTANCE = 10

        attr_accessor :session_key
        attr_accessor :session_id

        @queue_name = 'crawler_oxford'
        @job_class = 'Jobs::Crawlers::OxfordCrawler'

        def enqueue_all plan
          @wait = Selenium::WebDriver::Wait.new(timeout: 20) # seconds
          Headless.ly do
            @driver = Selenium::WebDriver.for_firefox_with_proxy
            begin
              url = "https://connect.werally.com/plans/oxhp"
              @driver.navigate.to url
              @wait.until do
                cookie = @driver.manage.all_cookies.find { |c| c[:name].include?("incap_ses_") }
                @session_key = cookie[:name]
                @session_id = cookie[:value]
              end
              @driver.quit
            rescue Exception => e
              # Make sure we quit the browser even if we run into an exception we didn't anticipate
              @driver.quit
              raise e
            end
          end

          specialties_for_plan = SPECIALTIES
          if plan.payor.name == 'United'
            specialties_for_plan = UNITED_COMMERCIAL_SPECIALTIES
          end

          specialties_for_plan.each_pair do |specialty_name, specialty_query_string|
            current_url = plan.url + "&zipCode=#{ZIP}&distanceMiles=#{DISTANCE}"
            current_url += "&" + specialty_query_string
            unless current_url.include?("from=")
              # just in case the seed data changes and the pagination param is no longer included
              current_url = current_url + "&from=0"
            end

            headers = {}
            headers["cookie"] = "#{@session_key}=#{@session_id}"
            headers["referer"] = "https://connect.werally.com/"
            response = RestClient.get(current_url, headers)
            json = JSON.parse(response)
            record_limit = json["total"]
            options = {}
            options["session_key"] = session_key
            options["session_id"] = session_id
            while !self.hit_record_limit? current_url, record_limit
              yield current_url, options
              current_url = self.next_page(current_url)
            end
          end
        end

        def next_page url
          url.sub(/from=([0-9]*)/) { "from=#{Regexp.last_match[1].to_i + PER_PAGE}" }
        end

        def hit_record_limit? url, limit
          page = 0
          url.scan(/from=([0-9]*)/) do 
            page = Regexp.last_match[1].to_i
          end
          page + PER_PAGE > limit
        end

      end
    end
  end
end