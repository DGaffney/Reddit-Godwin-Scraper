require 'rubygems'
require 'bundler/setup'
require 'digest/sha1'
require 'dm-core'
require 'dm-types'
require 'dm-aggregates'
require 'dm-validations'
require 'dm-migrations'
require 'dm-migrations/migration_runner'
require 'dm-chunked_query'
require 'eventmachine'
require 'em-http'
require 'fastercsv'
require 'hashie'
require 'json'
require 'nokogiri'
require 'ntp'
require 'open-uri'

DIR = File.dirname(__FILE__)
ENV['HOSTNAME'] = `hostname`.strip
ENV['PID'] = Process.pid.to_s #because ENV only allows strings.
ENV['INSTANCE_ID'] = Digest::SHA1.hexdigest("#{ENV['HOSTNAME']}#{ENV['PID']}")
ENV['DOMAIN'] = "http://www.reddit.com"

`ls #{DIR}/extensions`.split("\n").each do |extension_file|
  require DIR+"/extensions/"+extension_file
end
EXTENSIONS = [
  "float",
  "json",
  "dm-extensions",
  "array",
  "string"
]
EXTENSIONS.collect{|extensions| require DIR+'/extensions/'+extensions}
MODELS = [
  "comment",
  "godwin", 
  "sample"
]
MODELS.collect{|model| require DIR+'/models/'+model}

env = ARGV.include?("e") ? ARGV[ARGV.index("e")+1]||"development" : "development"

puts "Starting #{env} environment..."

database = YAML.load(File.read(File.dirname(__FILE__)+'/database.yml'))
if !database.has_key?(env)
  env = "development"
end
database = database[env]
puts database.inspect
puts DataMapper.setup(:default, "#{database["adapter"]}://#{database["username"]}:#{database["password"]}@#{database["host"]}:#{database["port"] || 3000}/#{database["database"]}").inspect
DataMapper.finalize
