DIR = File.dirname(__FILE__)
require DIR+'./run.rb'
DataMapper.auto_migrate!
