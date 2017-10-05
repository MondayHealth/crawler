require_relative 'base'
require "base64"

module Jobs
  module Crawlers
    class AbpnCrawler < Base
      URL = 'https://application.abpn.com/verifycert/verifyCert.asp?a=4&u=1'
      SPECIALTIES = {
        "Addiction Psychiatry": 11,
        "Child and Adolescent Psychiatry": 12,
        "Forensic Psychiatry": 15,
        "Geriatric Psychiatry": 16,
        "Neuropsychiatry": 21,
        "Psychiatry": 19
      }
      STATE = "NY"

      @queue = :crawler_abpn

      def self.enqueue_all options={}
        SPECIALTIES.each_key do |specialty_name|
          Resque.enqueue(Jobs::Crawlers::AbpnCrawler, specialty_name, STATE, options)
        end
      end

      def self.perform(specialty_name, state, options={})
        @ssdb = SSDB.new url: "ssdb://#{ENV['SSDB_HOST']}:#{ENV['SSDB_PORT']}"

        specialty_original_id = SPECIALTIES[specialty_name.to_sym]
        cache_key = URL + "&selSpclty=#{specialty_original_id}&selSt=#{state}"
        
        # If the page has already been fetched, block unless we're force refreshing
        unless options["force_refresh"]
          return if @ssdb.exists(cache_key)
        end

        page_source = nil
        with_retries(max_tries: 5, rescue: RestClient::Exception) do
          page_source = RestClient.post(URL, { selSpclty: specialty_original_id, selSt: state })
        end

        @ssdb.set(cache_key, sanitize_for_ssdb(page_source))

        STDOUT.puts("Enqueueing AbpnScraper with #{cache_key}")
        Resque.push('scraper_abpn', :class => 'Jobs::Scrapers::AbpnScraper', :args => [cache_key])
      end
    end
  end
end