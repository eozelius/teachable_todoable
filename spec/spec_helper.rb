ENV['RACK_ENV'] = 'test'
require "bundler/setup"
require "todoable"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # config.profile_examples = 5
  config.order = :random
  config.filter_run_when_matching :focus
  config.filter_gems_from_backtrace 'rack', 'rack-test', 'sinatra'
  config.default_formatter = "doc" if config.files_to_run.one?
  Kernel.srand config.seed
end