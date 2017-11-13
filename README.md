# Crawler

The Crawler is a microservice that crawls payor directories and saves their content to a shared key-value store.

When necessary, it runs a headless browser session through Firefox with [geckodriver](https://github.com/mozilla/geckodriver/) to simulate any user activities necessary.

## The Crawl Process

Crawls are kicked off for specific payors (e.g. Aetna) or directories (e.g. ABPN) with the tasks in `lib/tasks/refresh.rake`.

Each plan maps to a pagination strategy that runs whatever HTTP requests or browser sessions are required to get a list of URLS for the full crawl. Those are then passed off to a specific crawler, which does the same for the individual URL to get the page source. 

That data is then stored in SSDB, and a corresponding scraper job is queued up in the shared Resque backend. The scrapes themselves are handled by a [separate app](https://github.com/MondayHealth/scraper).

## Environment Variables

`QUEUE`: Controls Resque background jobs, and should always be `crawler_*` to match the queues in the job classes for this repo.

`REDIS_HOST`, `REDIS_PORT`, and `REDIS_PASS`: Used by Resque to connect to the Redis server.

`SSDB_HOST`, `SSDB_PORT`, `SSDB_PASS`: Used by the crawler jobs to connect to the SSDB server.

`DATABASE_URL`: Used by ActiveRecord to connect to the Postgres server.

`PRIVATE_GEM_OAUTH_TOKEN`: A Github x-oauth token used by Gemfile to pull private core repository with shared models, and passed to Docker with a custom build argument on deploy. 

To generate your own token, visit [this page](https://github.com/settings/tokens) and click "Generate new token".

If you need to set up the private repository token on a fresh server, run the following from the root folder after setting the environment variable: 

    dokku docker-options:add monday-scraper build '--build-arg private_gem_oauth_token=$PRIVATE_GEM_OAUTH_TOKEN'
