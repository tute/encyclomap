require 'bundler/setup'
Bundler.require

require './app'
if ENV['RACK_ENV'] == 'production'
  require './force-domain'
  use Rack::ForceDomain
end
run DescribeAround
