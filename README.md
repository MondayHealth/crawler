# Crawler

The Crawler is a microservice that crawls payor directories and saves their content to a shared key-value store.

When necessary, it runs a headless browser session through Firefox with [geckodriver](https://github.com/mozilla/geckodriver/) to simulate any user activities necessary.

## Before You Start

You'll need to create a `.env` file in the root directory with the [environment variables](#environment-variables) and then source them:

    source .env

You'll also need to set your bundler config with a private Oauth token for Github. To generate your own token, visit [this page](https://github.com/settings/tokens) and click "Generate new token", then run the following from the root folder:

    bundle config --local github.com $PRIVATE_GEM_OAUTH_TOKEN:x-oauth-basic

## Rake Tasks for Refreshing Crawls

    bundle exec rake payors:crawl
    bundle exec rake directories:crawl

## Deploys

New versions of the app are deployed by pushing to a remote dokku repository. 

### Set up the remote repository

    git remote add dokku dokku@monday-crawler:monday-crawler

### Deploy the master branch of the app

    git push dokku master

### Deploying another branch of the app

    git push dokku branch-name:master

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

If you need to set up the private repository token on a fresh server, run the following from the root folder after setting the environment variable: 

    dokku docker-options:add monday-crawler build '--build-arg private_gem_oauth_token=$PRIVATE_GEM_OAUTH_TOKEN'

### Special Environment Variables for Debugging

`SELENIUM_DEBUG`: When set to `1`, turns on debug logging for Selenium server. Useful when trying to figure out what's causing `Selenium::WebDriver::Error::ServerError` exceptions.

`RESTCLIENT_LOG`: When set to `stdout`, turns on STDOUT logging for RestClient. Useful if you need to replay network requests.