require_relative 'base'
require 'uri'

module Monday
  module Strategies
    module Pagination
      class Emblem < Base
        STATE = "NY"
        CITY = "New York"
        DISTANCE = 10

        DISCIPLINES = ["ABA,BCABA,BCBA", 
                       "CADC,CPC,CSW,LCSW,LMFC,LMFT,LMHC,LPC,MFC,MFT,MSW,OCSW,PAT,PC,QMHP,RN,RNCS",
                       "EDD,OPSY,PHD,PHDE,PSYD",
                       "LLP,MA,PSYE",
                       "AD,DO,MD,MDC",
                       "PPA",
                       "APRN",
                       "MH CENTER,OP CLINIC",
                       "EAP,LPN,MDNONPSY,MSN,OTHER,P GROUP,RNA,TCM,UNKNOWN"]

        SPECIALTY_GROUPS = [2, 10, 6, 7, 11, 9, 16, 15, 8, 13, 17, 3]

        @queue_name = 'crawler_emblem'
        @job_class = 'Jobs::Crawlers::EmblemCrawler'

        def enqueue_all plan
          @wait = Selenium::WebDriver::Wait.new(timeout: 20) # seconds
          Headless.ly do
            @driver = Selenium::WebDriver.for :firefox
            begin
              url = "https://www.valueoptions.com/referralconnect/providerDirectory.do"
              @driver.navigate.to url
              @wait.until do
                begin
                  # We need to pretend to select one insurance plan and accept the terms of service
                  # before our cookie will be whitelisted to pull search results
                  select_elem = Selenium::WebDriver::Support::Select.new(@driver.find_element(id: "listClient"))
                  select_elem.select_by(:value, "ehnco28")
                  submit_button = @driver.find_element(id: "go")
                  submit_button.click
                  @wait.until do
                    provider_link = @driver.find_element(xpath: "//a[@href='/referralconnect/providerSearch.do']")
                    provider_link.click
                    @wait.until do
                      accept_tos_link = @driver.find_element(xpath: "//a[@name='accept']")
                      accept_tos_link.click
                    end
                  end
                  true
                rescue Selenium::WebDriver::Error::NoSuchElementError => e
                  # Are we on an empty results page?
                  @driver.find_element(id: "noResultsSection")
                  true
                end

                @cookies = @driver.manage.all_cookies
              end

              @driver.quit
            rescue Exception => e
              # Make sure we quit the browser even if we run into an exception we didn't anticipate
              @driver.quit
              raise e
            end
          end

          DISCIPLINES.each do |discipline_list|
            SPECIALTY_GROUPS.each do |specialty_group_id|
              uri = URI.parse(plan.url)
              body = uri.query + "&txtCity=New+York&listState=#{STATE}&listdiscipline=#{discipline_list}&listSpecialtyGroups=#{specialty_group_id}"
              current_url = uri.to_s.sub("?" + uri.query, '')
              options = {}
              options["body"] = body
              
              cookie_string = @cookies.map do |cookie|
                "#{cookie[:name]}=#{cookie[:value]}"
              end.join("; ")
              options["cookie"] = cookie_string
              
              yield current_url, options
            end
          end
        end
      end
    end
  end
end

