require_relative 'base'

module Monday
  module Strategies
    module Pagination
      class Oscar < Base

        class TotalResultsMatchError < Exception; end

        PER_PAGE = 20

        SPECIALTIES = {
          "Marriage and Family Therapist": "142",
          "Mental Health Counselor": "052",
          "Psychiatrist specializing in pediatrics": "013",
          "Psychiatrist specializing in addiction problems": "002",
          "Psychiatrist specializing in geriatrics": "031",
          "Psychologist": "103",
          "Social Worker": "109"
        }
        ZIP = "10164"
        DISTANCE = 10

        @queue_name = 'crawler_oscar'
        @job_class = 'Jobs::Crawlers::OscarCrawler'

        def enqueue_all plan
          SPECIALTIES.each_pair do |specialty_name, specialty_id|
            current_url = plan.url + "&search_id=#{specialty_id}&zip_code=#{ZIP}&distance=#{DISTANCE}&page_start_idx=0"
            response = RestClient.get(current_url)
            total_results_match = response.body.match(/"totalResults":\s*([0-9]+)/)
            if total_results_match
              record_limit = total_results_match[1].to_i
              while !self.hit_record_limit? current_url, record_limit
                yield current_url
                current_url = self.next_page(current_url)
              end
            else
              raise TotalResultsMatchError.new("No match for total results in #{current_url}")
            end
          end
        end

        def next_page url
          url.sub(/page_start_idx=([0-9]*)/) { "page_start_idx=#{Regexp.last_match[1].to_i + PER_PAGE}" }
        end

        def hit_record_limit? url, limit
          page = 0
          url.scan(/page_start_idx=([0-9]*)/) do 
            page = Regexp.last_match[1].to_i
          end
          page + PER_PAGE > limit
        end
      end
    end
  end
end