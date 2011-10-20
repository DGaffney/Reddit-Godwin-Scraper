class Sample
  #ttg = time to godwin
  include DataMapper::Resource
  property :id, Serial
  property :created_at, Time
  property :post_count, Integer
  property :comment_count, Integer
  property :num_godwins, Integer
  property :avg_ttg, Float
  property :median_ttg, Float
  property :avg_ctg, Float
  property :median_ctg, Float
  
  def finalize_properties(stats)
    self.created_at = Time.now
    self.post_count = Comment.count(:sample_id => self.id, :parent_id => nil)
    self.comment_count = Comment.count(:sample_id => self.id, :parent_id.not => nil)
    self.num_godwins = Godwin.count(:sample_id => self.id, :godwin => true)
    self.avg_ttg = stats[:ttgs].avg
    self.median_ttg = stats[:ttgs].med
    self.avg_ctg = stats[:ctgs].avg
    self.median_ctg = stats[:ctgs].med
  end
end