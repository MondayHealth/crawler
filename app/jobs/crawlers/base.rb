require_relative '../concerns/logged_job'

module Jobs
  module Crawlers
    class Base
      extend Jobs::Concerns::LoggedJob

      def self.sanitize_for_ssdb html
        html.gsub("\n", " ").gsub("\t", " ").gsub(/\s+/, " ")
      end
    end
  end
end