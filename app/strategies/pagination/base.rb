module Monday
  module Strategies
    module Pagination
      class Base
        class << self;
          attr_accessor :queue_name
          attr_accessor :job_class
        end
      end
    end
  end
end