$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "bundler/setup"
require 'resque/tasks'
load "tasks/otr-activerecord.rake"
load "tasks/refresh.rake"

namespace :db do
  # Some db tasks require your app code to be loaded; they'll expect to find it here
  task :environment do
    require 'active_record'

    Bundler.require :default
    require_relative 'environment'
  end
end

task 'resque:setup' => 'db:environment'