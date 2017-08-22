ENV['REDIS_HOST'] ||= "localhost"
ENV['REDIS_PORT'] ||= "6379"
ENV['REDIS_PASS'] ||= ""

require 'headless'
require 'selenium-webdriver'
require 'redis'
require 'moneta'

PAGE_URL = 'http://www.aetna.com/dse/search?site_id=docfind&langpref=en&tabKey=tab1#markPage=clickedDistance&whyPressed=geo&searchQuery=All%20Behavioral%20Health%20Professionals&searchTypeMainTypeAhead=&searchTypeThrCol=byProvType&mainTypeAheadSelectionVal=&thrdColSelectedVal=All%20Behavioral%20Health%20Professionals&aetnaId=&Quicklastname=&Quickfirstname=&QuickZipcode=1019%5C9&QuickCoordinates=40.7427%2C-73.99340000000001&quickCategoryCode=&QuickGeoType=city&geoSearch=New%20York%20City%2C%20New%20York&geoMainTypeAheadLastQuickSelectedVal=New%20York%20City%2C%20New%20Yo%5Crk&geoBoxSearch=true&stateCode=NY&quickSearchTerm=&classificationLimit=&pcpSearchIndicator=&specSearchIndicator=&suppressFASTDocCall=true&linkwithoutplan=&publicPlan=AWMTS&displayPlan=%28NY%29%20Ae%5Ctna%20Whole%20Health%u2120%20-%20Mount%20Sinai%20Health%20Partners%20Plus&zip=&filterValues=&pagination=&radius=0&lastPageTravVal=&sendZipLimitInd=&site_id=docfind&sortOrder=distance&ioeqSelectionInd=&ioe_qType=&switchForStatePlanSelectionPopUp=&actualDisplayTerm=All%20Behavioral%20Health%20Professionals&withinMilesVal='

headless = Headless.new
headless.start
driver = Selenium::WebDriver.for :firefox
driver.navigate.to PAGE_URL
wait = Selenium::WebDriver::Wait.new(timeout: 20) # seconds
wait.until do
  begin
    driver.find_element(id: "pageNumbers")
    true
  rescue Selenium::WebDriver::Error::ServerError => e
    unless e.message =~ /404/
      raise e
    end
  end
end

redis = Redis.new(:host => ENV['REDIS_HOST'], :port => ENV['REDIS_PORT'], :password => ENV['REDIS_PASS']) 
store = Moneta.new(:Redis, backend: redis)
store[PAGE_URL] = driver.page_source

puts store[PAGE_URL]

headless.destroy
