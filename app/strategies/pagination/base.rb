module Monday
  module Strategies
    module Pagination
      class Base
        class << self;
          attr_accessor :queue_name
          attr_accessor :job_class

        end

        def cookie_string
          @cookies = @driver.manage.all_cookies
          cookie_string = @cookies.map do |cookie|
            "#{cookie[:name]}=#{cookie[:value]}"
          end.join("; ")
        end
      end
    end
  end
end