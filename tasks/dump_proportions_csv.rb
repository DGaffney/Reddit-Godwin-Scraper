DIR = File.dirname(__FILE__)
require DIR+'./run.rb'
path = ARGV[0]||"proportions.csv"
Comment.calculate_proportion_godwinned(path)