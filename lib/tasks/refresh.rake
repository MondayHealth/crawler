require 'json'

namespace :payors do
  desc "Refreshes payors with a full crawl"
  task :crawl => ['db:environment'] do
    query = ENV['PAYORS'] ? Payor.find_by(name: ENV['PAYORS']).plans : Plan.all
    query.find_each do |plan|
      strategy = plan.pagination_strategy
      strategy.enqueue_all(plan) do |url, options={}|
        STDOUT.puts("Enqueueing #{strategy.class.job_class} with [#{plan.id}, #{url}, #{options.inspect}]")
        Resque.push(strategy.class.queue_name, :class => strategy.class.job_class, :args => [plan.id, url, options])
      end
    end
  end
end

namespace :directories do
  desc "Refreshes directories with a full crawl"
  task :crawl => ['db:environment'] do
    Jobs::Crawlers::AbpnCrawler.enqueue_all
    Jobs::Crawlers::GoodTherapyCrawler.enqueue_all
  end
end