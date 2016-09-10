#! /usr/local/bin/ruby -w
# TODO: Move the Driver class to its own file
# TODO: Factor out and generalize ENV Validation

$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
$VERBOSE = nil # tell ruby to shut the hell up

require 'rubygems'
require 'bundler/setup'

require 'reddit/driver'

# ENV Validation #
%w(reddit_client_id
   reddit_client_secret
   reddit_username
   reddit_password)
  .select { |k| !ENV[k] }
  .map { |k| puts "ENV['#{k}'] missing" }
  .map { abort('environment missing') }
##################

# Script Intro #
puts 'Hello, world!'
puts "Process ID: #{Lemtzas::Common::Tracking.script_uuid}"
################

# Run it
driver = Lemtzas::Reddit::Monitor::Driver.new
driver.track
puts "Driver ID: #{driver.uuid}"
driver.run
