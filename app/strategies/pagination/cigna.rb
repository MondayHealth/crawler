require_relative 'base'
require 'uri'

module Monday
  module Strategies
    module Pagination
      class Cigna < Base
        SUGGESTIONS_CODES = {
          "Addiction Psychology": "PAB",
          "Child Psychology": "PJC",
          "Counseling": "PCN",
          "Psychiatry": "PPY",
          "Psychiatry, Child & Adolescent": "PYC",
          "Psychiatry, Forensic": "PYF",
          "Psychiatry, Geriatric": "PGR",
          "Psychology": "PPJ",
          "Psychology, Neurological": "PNY",
          "Social Work": "PSW"
        }

        @queue_name = 'crawler_cigna'
        @job_class = 'Jobs::Crawlers::CignaCrawler'

        def enqueue_all plan
          SUGGESTIONS_CODES.values.each do |specialty_code|
            yield plan.url, { "specialty_code" => specialty_code }
          end
        end
      end
    end
  end
end
