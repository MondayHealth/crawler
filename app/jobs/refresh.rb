module Monday
  module Jobs
    class Refresh
      @queue = :crawler_refresh_payor

      def self.perform plan_id
        plan = Plan.find(plan_id)
        strategy = plan.pagination_strategy
        strategy.enqueue_all(plan) do |url, options={}|
          STDOUT.puts("Enqueueing #{strategy.class.job_class} with [#{plan.id}, #{url}, #{options.inspect}]")
          Resque.push(strategy.class.queue_name, :class => strategy.class.job_class, :args => [plan.id, url, options])
        end
      end
    end
  end
end