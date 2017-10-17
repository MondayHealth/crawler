require_relative 'base'

module Monday
  module Strategies
    module Pagination
      class Aetna < Base
        PER_PAGE = 25

        @queue_name = 'crawler_aetna'
        @job_class = 'Jobs::Crawlers::AetnaCrawler'

        def enqueue_all plan
          current_url = plan.url
          while !self.hit_record_limit? current_url, plan.record_limit
            yield current_url
            current_url = self.next_page(current_url)
          end
        end

        def next_page url
          url.sub(/pagination=([0-9]*)/) { "pagination=#{Regexp.last_match[1].to_i + PER_PAGE}" }
        end

        def hit_record_limit? url, limit
          page = 0
          url.scan(/pagination=([0-9]*)/) do 
            page = Regexp.last_match[1].to_i
          end
          page + PER_PAGE > limit
        end
      end
    end
  end
end