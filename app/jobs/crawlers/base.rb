require_relative '../concerns/logged_job'

module Jobs
  module Crawlers
    class Base
      extend Jobs::Concerns::LoggedJob

      def self.sanitize_for_ssdb html
        html.gsub("\n", " ").gsub("\t", " ").gsub(/\s+/, " ")
      end

      def self.ssdb
        @ssdb ||= SSDB.new url: "ssdb://#{ENV['SSDB_HOST']}:#{ENV['SSDB_PORT']}"
      end
    end
  end
end