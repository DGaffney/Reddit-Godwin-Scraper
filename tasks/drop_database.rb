DIR = File.dirname(__FILE__)
require DIR+'../run.rb'
MODELS.each do |model|
  model.classify.constantize.delete
end