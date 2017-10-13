require_relative '../concerns/logged_job'

module Jobs
  module Crawlers
    class Base
      extend Jobs::Concerns::LoggedJob

      def self.sanitize_for_ssdb html
        # need to convert to UTF-8 to avoid "invalid byte sequence in US-ASCII" errors
        to_utf8(html).gsub("\n", " ").gsub("\t", " ").gsub(/\s+/, " ")
      end

      def self.to_utf8(str)
        str = str.force_encoding("UTF-8")
        return str if str.valid_encoding?
        str = str.force_encoding("BINARY")
        str.encode("UTF-8", invalid: :replace, undef: :replace)
      end
    end
  end
end