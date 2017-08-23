class Plan < ActiveRecord::Base
  def pagination_strategy
    return Monday::Strategies::Pagination::Aetna.new
  end
end