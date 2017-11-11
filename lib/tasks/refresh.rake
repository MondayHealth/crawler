require 'json'

namespace :payors do
  desc "Refreshes payors with a full crawl"
  task :crawl => ['db:environment'] do
    query = ENV['PAYORS'] ? Payor.find_by(name: ENV['PAYORS']).plans : Plan.all
    query.find_each do |plan|
      Resque.enqueue(Monday::Jobs::Refresh, plan.id)
    end
  end
end

namespace :directories do
  desc "Refreshes directories with a full crawl"
  task :crawl => ['db:environment'] do
    Jobs::Crawlers::AbpnCrawler.enqueue_all
    Jobs::Crawlers::GoodTherapyCrawler.enqueue_all
    Jobs::Crawlers::PsychologyTodayCrawler.enqueue_all
  end
end