require "rails_helper"
require "rails/generators"
require "rails/generators/testing/behavior"
require "generators/query_owl/install/install_generator"

RSpec.describe QueryOwl::Generators::InstallGenerator do
  include FileUtils
  include Rails::Generators::Testing::Behavior

  def file(relative) = Pathname.new(destination_root).join(relative)

  tests QueryOwl::Generators::InstallGenerator
  destination File.expand_path("../../../tmp/generator_test", __dir__)

  before { prepare_destination }
  after  { FileUtils.rm_rf(destination_root) }

  it "creates the initializer file" do
    run_generator
    expect(file("config/initializers/query_owl.rb")).to exist
  end

  it "includes all config options in the initializer" do
    run_generator
    content = file("config/initializers/query_owl.rb").read
    %w[
      enabled n_plus_one_threshold slow_query_threshold_ms
      log_level backtrace_lines backtrace_filter
      raise_on_n_plus_one event_store_size dashboard_enabled log_file
    ].each do |option|
      expect(content).to include("config.#{option}")
    end
  end

  it "generates all options commented out by default" do
    run_generator
    content = file("config/initializers/query_owl.rb").read
    uncommented = content.lines.reject { |l| l.strip.start_with?("#") || l.strip.empty? }
    expect(uncommented).to eq(["QueryOwl.configure do |config|\n", "end\n"])
  end
end