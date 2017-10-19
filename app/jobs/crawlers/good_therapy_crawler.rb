require_relative 'base'

module Jobs
  module Crawlers
    class GoodTherapyCrawler < Base
      URL = 'https://www.goodtherapy.org/search-service.html?ch&search[miles]=10&search[zipcode]=<CITY>&nonjs=1&search[p]=<PAGE>'
      PER_PAGE = 10

      @queue = :crawler_good_therapy

      def self.enqueue_all options={}
        city = "New York City, NY"
        search_url = URL.sub("<CITY>", URI.escape(city)).sub("<PAGE>", "1")
        response = RestClient.get(search_url)
        json = JSON.parse(response.body)
        total_pages = json["totalcount"] / PER_PAGE + 1
        total_pages.times do |page|
          Resque.enqueue(Jobs::Crawlers::GoodTherapyCrawler, city, page + 1, response.cookies, options)
        end
      end

      def self.perform city, page, cookies, options={}
        search_url = URL.sub("<CITY>", URI.escape(city)).sub("<PAGE>", page.to_s)
        response = RestClient.get(search_url, cookies: cookies)
        json = JSON.parse(response.body)
        
        # sometimes we get an array, sometimes we get a hash with numbers as the keys
        # in both cases, we just case about the values, not the ordering
        items = json["todisplay"]
        if items.is_a?(Hash)
          items = items.values
        end

        items.each do |record|
          url_slug = record["seo_friendly"]
          Resque.enqueue(Jobs::Crawlers::Detail::GoodTherapyDetailCrawler, url_slug, options)
        end
      end
    end
  end
end