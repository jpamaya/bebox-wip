# Add coverage with simple_cov and codeclimate
# These must be the first lines in the file
require 'codeclimate-test-reporter'
require 'simplecov'

formatters = [SimpleCov::Formatter::HTMLFormatter]
formatters << CodeClimate::TestReporter::Formatter if ENV['CODECLIMATE_REPO_TOKEN']

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[*formatters]
SimpleCov.start do
  add_filter '/spec/'
end

require 'rubygems'
require 'awesome_print'
require 'jazz_hands'
require 'pry'
require 'factory_girl'
require 'net/ssh'
require 'fakefs/safe'
require 'fakecmd'

require_relative '../lib/bebox'

I18n.enforce_available_locales = false

RSpec.configure do |config|

  config.before(:suite) do
    FastGettext.add_text_domain('bebox', path: "#{Dir.pwd}/lib/i18n", type: :yaml)
    FastGettext.set_locale('en')
    FastGettext.text_domain = 'bebox'
  end

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:each) do
    ENV['RUBY_ENV'] = 'test'
  end

  config.after(:each) do
    ENV['RUBY_ENV'] = 'development'
  end

  # Factory Girl methods
  config.include FactoryGirl::Syntax::Methods
end