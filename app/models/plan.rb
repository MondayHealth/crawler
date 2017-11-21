class Plan < ActiveRecord::Base
  def pagination_strategy
    case payor.name
    when 'Aetna'
      return Monday::Strategies::Pagination::Aetna.new
    when 'Oscar'
      return Monday::Strategies::Pagination::Oscar.new
    when 'United'
      if self.name == 'Commercial'
        return Monday::Strategies::Pagination::Oxford.new
      else
        return Monday::Strategies::Pagination::United.new
      end
    when 'Oxford'
      return Monday::Strategies::Pagination::Oxford.new
    when 'Emblem'
      return Monday::Strategies::Pagination::Emblem.new
    when 'CareConnect'
      return Monday::Strategies::Pagination::CareConnect.new
    when 'Cigna'
      return Monday::Strategies::Pagination::Cigna.new
    when 'Empire'
      return Monday::Strategies::Pagination::Empire.new
    end
  end
end