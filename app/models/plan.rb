class Plan < ActiveRecord::Base
  belongs_to :provider

  def pagination_strategy
    return Monday::Strategies::Pagination::Aetna.new
  end
end