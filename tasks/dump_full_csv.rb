DIR = File.dirname(__FILE__)
require DIR+'./run.rb'
path = ARGV[0]||"full.csv"
Comment.posts_to_csv(path)