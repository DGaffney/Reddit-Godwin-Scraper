class Comment
  include DataMapper::Resource
  property :id, Serial
  property :author, String, :index => [:author]
  property :author_flair_css_class, String
  property :author_flair_text, Text
  property :body, Text
  property :body_html, Text
  property :created, Time
  property :created_utc, Time
  property :domain, String, :index => [:domain]
  property :downs, Integer
  property :hidden, Boolean
  property :reddit_id, String, :unique_index => [:unique_post]
  property :levenshtein, String
  property :likes, String
  property :link_id, String, :index => [:link_id]
  property :name, String
  property :num_comments, Integer
  property :over_18, Boolean
  property :parent_id, String, :index => [:parent_id]
  property :permalink, Text
  property :score, Integer
  property :subreddit, String, :index => [:subreddit]
  property :subreddit_id, String
  property :title, String
  property :ups, Integer
  property :url, Text
  property :sample_id, Integer
  belongs_to :sample, :child_key => :sample_id, :index => [:sample_id]
  has 1, :godwin
  
  def self.all_posts
    Comment.all(:parent_id => nil)
  end
  
  def parent
    Comment.first(:name => self.parent_id)
  end
  
  def comments
    if self.post?
      return Comment.all(:parent_id => self.name)
    else
      return Comment.all(:name => self.parent_id)
    end
  end
  
  def resolve_stats
    stats = {}
    begin
    stats[:num_comments] = self.num_comments
    stats[:total_comments] = self.comments.length
    stats[:total_duration] = self.comments.sort{|x,y| x.created_utc<=>y.created_utc}.last.created_utc.to_i-self.created_utc.to_i
    stats[:mentioned_hitler] = !self.comments.collect{|comment| comment.body}.join(" ").downcase.scan(/\W*hitler\W*/).flatten.empty?
    stats[:mentioned_nazis] = !self.comments.collect{|comment| comment.body}.join(" ").downcase.scan(/\W*nazi\W*/).flatten.empty?
    stats[:godwinned] = stats[:mentioned_hitler] || stats[:mentioned_nazis]
    stats[:time_to_godwin] = stats[:godwinned] ? self.comments.select{|comment| !comment.body.downcase.scan(/\W*hitler\W*/).flatten.empty? || !comment.body.downcase.scan(/\W*nazi\W*/).flatten.empty?}.sort{|x,y| x.created_utc<=>y.created_utc}.first.created_utc.to_i-self.created_utc.to_i : 0
    stats[:count_to_godwin] = stats[:godwinned] ? self.comments.sort{|x,y| x.created_utc<=>y.created_utc}.index(self.comments.sort{|x,y| x.created_utc<=>y.created_utc}.select{|comment| comment.body.downcase.scan(/\W*hitler\W*/).flatten.empty? || comment.body.downcase.scan(/\W*nazi\W*/).flatten.empty?}.first) : 0
    stats[:first_godwin_id] = stats[:godwinned] ? self.comments.select{|comment| !comment.body.downcase.scan(/\W*hitler\W*/).flatten.empty? || !comment.body.downcase.scan(/\W*nazi\W*/).flatten.empty?}.sort{|x,y| x.created_utc<=>y.created_utc}.first.id : 0
    stats[:first_godwin_reddit_id] = stats[:godwinned] ? self.comments.select{|comment| !comment.body.downcase.scan(/\W*hitler\W*/).flatten.empty? || !comment.body.downcase.scan(/\W*nazi\W*/).flatten.empty?}.sort{|x,y| x.created_utc<=>y.created_utc}.first.reddit_id : 0
    stats[:id] = self.id
    stats[:reddit_id] = self.reddit_id
    stats[:created_utc] = self.created_utc
    stats[:ups] = self.ups
    stats[:downs] = self.downs
rescue
end
    stats
  end
  
  def self.posts_to_csv(path)
    posts = Comment.all(:parent_id => nil)
    post_data = []
    posts.each do |post|
      post_data << post.resolve_stats
    end
    csv = FasterCSV.open(path, "w")
    keys = post_data.first.keys
    csv << keys
    post_data.each do |post|
      csv << keys.collect{|key| post[key]}
    end
    csv.close
    puts "Wrote to #{path}."
    `open #{path}`
  end
  
  def post?
    return self.parent_id.nil?
  end
  
def self.calculate_proportion_godwinned(path)
    set = []
    1.upto(500) do |x|
      begin
        sample = {}
        sample["count"] = x
        sample["clean"] = Comment.all(:parent_id => nil, :num_comments => x).select{|c| c.godwin.nil? }.length
        sample["godwin"] = Comment.all(:parent_id => nil, :num_comments => x).select{|c| !c.godwin.nil? }.length
        sample["proportion"] = sample["godwin"]/(sample["clean"].to_f+sample["godwin"])
        set << sample
      rescue
        next
      end
    end
    csv = FasterCSV.open(path, "w")
    keys = set.first.keys
    csv << keys
    set.each do |sample|
      csv << keys.collect{|key| sample[key]}
    end
    csv.close
    puts "Wrote to #{path}."
    `open #{path}`
  end
end

