require 'json'

namespace :providers do
  namespace :refresh do
    desc "Refreshes providers with a full crawl"
    task :crawl => ['db:environment'] do
      refresh('Jobs::Crawlers::AetnaCrawler', 'crawler_aetna')
    end

    desc "Refreshes providers with cached data"
    task :scrape => ['db:environment'] do
      refresh('Jobs::Scrapers::AetnaScraper', 'scraper_aetna')
    end

    def refresh(job_class, queue_name)
      Plan.find_each do |plan|
        strategy = plan.pagination_strategy
        current_url = plan.url
        while !strategy.hit_record_limit? current_url, plan.record_limit
          STDOUT.puts("Enqueueing #{job_class} with [#{plan.id}, #{current_url}]")
          Resque.push(queue_name, :class => job_class, :args => [plan.id, current_url])
          current_url = strategy.next_page(current_url)
        end
      end
    end
  end
end