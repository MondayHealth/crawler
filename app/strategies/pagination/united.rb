module Monday
  module Strategies
    module Pagination
      class United < Base
        @queue_name = 'crawler_united'
        @job_class = 'Jobs::Crawlers::UnitedCrawler'

        def enqueue_all plan
          # there's no pagination for United results as they come down in one big JSON blob
          yield plan.url
        end
      end
    end
  end
end