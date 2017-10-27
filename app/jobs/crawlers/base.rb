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

      def self.ssdb
        @ssdb ||= SSDB.new url: "ssdb://#{ENV['SSDB_HOST']}:#{ENV['SSDB_PORT']}"
      end

      def self.cookie_string
        @cookies = @driver.manage.all_cookies
        cookie_string = @cookies.map do |cookie|
          "#{cookie[:name]}=#{cookie[:value]}"
        end.join("; ")
      end
    end
  end
end