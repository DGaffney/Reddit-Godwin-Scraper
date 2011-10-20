class Godwin
  include DataMapper::Resource
  property :id, Serial
  property :godwin, Boolean, :index => [:godwin_count]
  property :comment_id, Integer
  property :sample_id, Integer, :index => [:sample_group]
  belongs_to :comment, :child_key => :comment_id
  belongs_to :sample, :child_key => :sample_id
end