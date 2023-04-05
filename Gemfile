source 'https://rubygems.org'

gem 'rake'
gem 'cocoapods', '~> 1.11', '>= 1.11.2'
gem 'xcpretty-travis-formatter'
gem 'octokit', "~> 4.0"
gem 'fastlane', '~> 2.199', '>= 2.199.0'
gem 'dotenv'
gem 'commonmarker', '>= 0.23.7'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
