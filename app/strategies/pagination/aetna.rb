module Monday
  module Strategies
    module Pagination
      class Aetna
        PER_PAGE = 25

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