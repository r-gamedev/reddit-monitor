#! /usr/local/bin/ruby -w
# TODO: Move the Driver class to its own file
# TODO: Factor out and generalize ENV Validation

$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
$VERBOSE = nil # tell ruby to shut the hell up

require 'rubygems'
require 'bundler/setup'
require 'yaml'

require 'reddit/driver'

# ENV Validation #
%w(reddit_client_id
   reddit_client_secret
   reddit_username
   reddit_password
   reddit_subreddit_name
   reddit_scan_modmail
   rabbitmq_url)
  .select { |k| !ENV[k] }
  .map { |k| puts "ENV['#{k}'] missing" }
  .map { abort('environment missing') }
##################

# Trick to allow a variety of truthy and falsy values.
reddit_scan_modmail = !!YAML.load(ENV['reddit_scan_modmail'])

# Script Intro #
puts 'Hello, world!'
puts "Process ID: #{Lemtzas::Common::Tracking.script_uuid}"
puts "Subreddit to scan: #{ENV['reddit_subreddit_name']}"
pubs "Scan Modmail? '#{ENV['reddit_scan_modmail']}' interpreted as '#{reddit_scan_modmail}'"
################

# Run it
driver = Lemtzas::Reddit::Monitor::Driver.new(
  subreddit_name: ENV['reddit_subreddit_name'],
  scan_modmail: reddit_scan_modmail)
driver.track
puts "Driver ID: #{driver.uuid}"
driver.run
