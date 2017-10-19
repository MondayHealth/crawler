class Plan < ActiveRecord::Base
  def pagination_strategy
    case payor.name
    when 'Aetna'
      return Monday::Strategies::Pagination::Aetna.new
    when 'Oscar'
      return Monday::Strategies::Pagination::Oscar.new
    when 'United'
      return Monday::Strategies::Pagination::United.new
    end
  end
end