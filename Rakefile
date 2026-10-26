require "bundler/setup"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

require "bundler/gem_tasks"
require 'rubocop/rake_task'
require 'bundler/audit/task'
require 'rspec/core/rake_task'

RuboCop::RakeTask.new(:lint)
Bundler::Audit::Task.new
RSpec::Core::RakeTask.new(:spec)

desc "Run Brakeman static security analysis"
task :brakeman do
  sh "bundle exec brakeman -q --no-pager --force-scan --skip-files spec/dummy/ -p . -i config/brakeman.ignore"
end

desc "Audit the Appraisal-style gemfiles/ lockfiles"
task :"bundle:audit:gemfiles" do
  Dir["gemfiles/*.gemfile.lock"].sort.each do |lockfile|
    sh "bundle exec bundle-audit check --gemfile-lock #{lockfile}"
  end
end

task default: [:lint, :'bundle:audit:update', 'bundle:audit:check', :'bundle:audit:gemfiles', :brakeman, :spec]

desc "Run performance benchmarks"
task :benchmark do
  ruby "benchmarks/benchmark.rb"
end
