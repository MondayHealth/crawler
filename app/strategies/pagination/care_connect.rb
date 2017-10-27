require_relative 'base'
require 'uri'

module Monday
  module Strategies
    module Pagination
      class CareConnect < Base
        PAGE_SIZE = 20
        AJAX_LIST_URL = 'https://www.providerlookuponline.com/Northshore/po7/Client_POWebService.asmx/GetProviders'

        @queue_name = 'crawler_care_connect'
        @job_class = 'Jobs::Crawlers::CareConnectCrawler'

        def enqueue_all plan
          @wait = Selenium::WebDriver::Wait.new(timeout: 20)
          Headless.ly do
            @driver = Selenium::WebDriver.for :firefox
            begin
              url = "https://www.providerlookuponline.com/Northshore/po7/Results.aspx"
              @driver.navigate.to url
              plan_link = nil
              @wait.until do
                plan_link = @driver.find_element(xpath: "//a[contains(text(), 'CareConnect')]")
                plan_link.enabled? && plan_link.displayed?
              end
              sleep 1
              plan_link.click

              zipcode_field = @driver.find_element(id: "zipcode")
              zipcode_field.send_keys("10104")

              # to move to the next step in the page, we need to blur the zip field and wait for the 
              # page to reload its links over AJAX—unfortunately seems like the only way to do this is
              # with a timed sleep right now, but with more time there might be some event we can listen
              # for to remove the hard-coded timer
              @driver.execute_script("document.getElementById('zipcode').dispatchEvent(new Event('blur'))")
              sleep 5

              provider_link = nil
              @wait.until do
                provider_link = @driver.find_element(xpath: "//a[contains(text(), 'Behavioral Health')]")
                provider_link.enabled? && provider_link.displayed?
              end
              provider_link.click

              provider_count_container = nil
              @wait.until do
                provider_count_container = @driver.find_element(css: ".providerCount")
                provider_count_container.attribute("innerHTML") =~ /[0-9]+/
              end
              record_limit = provider_count_container.attribute("innerHTML").to_i
              STDOUT.puts("Found #{record_limit} results")

              current_url = AJAX_LIST_URL
              options = {}
              options["cookie"] = self.cookie_string
              options["data"] = { "startIndex" => 0,
                                  "pageSize" => PAGE_SIZE,
                                  "sortOrder" => 0,
                                  "customSortName" => nil }
              data = options["data"]
              while data["startIndex"].to_i + data["pageSize"].to_i <= record_limit
                yield current_url, options
                data["startIndex"] = data["pageSize"] + data["startIndex"].to_i
                self.next_page!(options)
              end
              
              @driver.quit
            rescue Exception => e
              # Make sure we quit the browser even if we run into an exception we didn't anticipate
              @driver.quit
              raise e
            end
          end
        end

        def next_page!(options)
          data = options["data"]
          data["startIndex"] = data["startIndex"].to_i + data["pageSize"].to_i
        end
      end
    end
  end
end
