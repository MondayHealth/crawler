require_relative '../concerns/logged_job'

module Jobs
  module Crawlers
    class Base
      extend Jobs::Concerns::LoggedJob
    end
  end
end