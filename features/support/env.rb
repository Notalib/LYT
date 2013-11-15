require 'debugger'
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'capybara'
require 'capybara/dsl'
require 'capybara/cucumber'

Capybara.configure do |config|
  config.run_server = false
  config.default_driver = :selenium
  target_dir = ENV['LYT_DESTINATION_DIR'] || ENV['USER']
  config.app_host = "http://#{ENV['LYT_HOST']}/#{target_dir}"
#  config.default_wait_time = 10
  # Alternatively see http://how.itnig.net/facts/how-to-avoid-intermittent-errors-on-capybara-and-selenium
end


#Capybara.javascript_driver = :akephalos
#Capybara.register_driver :akephalos do |app|
#  Capybara::Driver::Akephalos.new(app, :validate_scripts => false)
#end

Before do
end
