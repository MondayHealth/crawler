require 'json'

namespace :payors do
  namespace :refresh do
    desc "Refreshes payors with a full crawl"
    task :crawl => ['db:environment'] do
      refresh
    end

    def refresh
      Plan.find_each do |plan|
        strategy = plan.pagination_strategy
        strategy.enqueue_all(plan) do |url|
          STDOUT.puts("Enqueueing #{strategy.class.job_class} with [#{plan.id}, #{url}]")
          Resque.push(strategy.class.queue_name, :class => strategy.class.job_class, :args => [plan.id, url])
        end
      end
    end
  end
end

namespace :directories do
  namespace :refresh do
    desc "Refreshes directories with a full crawl"
    task :crawl => ['db:environment'] do
      Jobs::Crawlers::AbpnCrawler.enqueue_all
    end
  end
end