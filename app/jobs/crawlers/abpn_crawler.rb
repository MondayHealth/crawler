require_relative 'base'

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

      def self.enqueue_all
        SPECIALTIES.each_key do |specialty_name|
          Resque.enqueue(Jobs::Crawlers::AbpnCrawler, specialty_name, STATE)
        end
      end

      def self.perform(specialty_name, state, options={})
        @ssdb = SSDB.new url: "ssdb://#{ENV['SSDB_HOST']}:#{ENV['SSDB_PORT']}"

        specialty_original_id = SPECIALTIES[specialty_name.to_sym]
        cache_key = URL + "&selSpclty=#{specialty_original_id}&selSt=#{state}"
        
        # If the page has already been fetched, block unless we're force refreshing
        unless options[:force_refresh]
          return if @ssdb.exists(cache_key)
        end

        page_source = RestClient.post(URL, { selSpclty: specialty_original_id, selSt: state })

        @ssdb.set(cache_key, page_source)
      end
    end
  end
end