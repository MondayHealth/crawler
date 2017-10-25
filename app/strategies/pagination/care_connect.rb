require_relative 'base'
require 'uri'

module Monday
  module Strategies
    module Pagination
      class CareConnect < Base
        @queue_name = 'crawler_care_connectx'
        @job_class = 'Jobs::Crawlers::CareConnectCrawler'

        def enqueue_all plan
          @wait = Selenium::WebDriver::Wait.new(timeout: 20) # seconds
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
              plan_link.click

              zipcode_field = @driver.find_element(id: "zipcode")
              zipcode_field.send_keys("10104")
              @driver.execute_script("document.getElementById('zipcode').dispatchEvent(new Event('blur'))")

              provider_link = nil
              @wait.until do
                sleep 1
                provider_link = @driver.find_element(xpath: "//a[contains(text(), 'Behavioral Health')]")
                provider_link.enabled? && provider_link.displayed?
              end
              provider_link.click

              @wait.until do
                @driver.find_element(css: ".providerCountContainer")
              end
            end
          end
        end
      end
    end
  end
end
