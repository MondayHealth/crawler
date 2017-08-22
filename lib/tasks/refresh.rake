namespace :providers do
  desc "Refreshes Providers"
  task :refresh => ['db:environment'] do
    Plan.find_each do |plan|
      strategy = plan.pagination_strategy
      current_url = plan.url
      while !strategy.hit_record_limit? current_url, plan.record_limit
        Monday::Queue.queue.push(current_url)
        current_url = strategy.next_page(current_url)
      end
    end
  end
end