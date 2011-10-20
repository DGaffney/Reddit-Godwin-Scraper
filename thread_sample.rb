load "run.rb"
class ThreadSample
  attr_accessor :sample, :k_step, :n, :subreddits, :polished_sample, :current_post_url
  def initialize
    @sample = []
    @k_step = 1
    @n = 100000
    @subreddits = []
    @polished_sample = []
    @current_post_url = "" 
  end
  
  def collect_sample
    current_page = Nokogiri::parse(open(ENV['DOMAIN']))
    top_article_threads = current_page.search("a").select{ |link| link.attributes["class"] && link.attributes["class"].value == "comments"}
    paginations = 0
    next_page_link = current_page.search("a").select{ |link| link.attributes["rel"] && link.attributes["rel"].value == "nofollow next" }.first.attributes["href"].value
    this_step = 0
    while !next_page_link.nil?#this_step < top_article_threads.length && @sample.length < @n
      if (this_step.to_f/@k_step).whole? && this_step != 0
        if @subreddits.include?(top_article_threads[this_step-1].attributes["href"].value.scan(/http:\/\/www.reddit.com\/r\/(\w*)/).flatten.first) || @subreddits.empty?
          @sample << top_article_threads[this_step-1].attributes["href"].value
          puts "Added #{@sample.last}..."
        end
      end
      this_step += 1
      if this_step >= top_article_threads.length
        puts "***Shifting to next page...***"
        current_page = Nokogiri::parse(open(next_page_link).read)
        top_article_threads = current_page.search("a").select{ |link| link.attributes["class"] && link.attributes["class"].value == "comments"}
        next_page_link = current_page.search("a").select{ |link| link.attributes["rel"] && link.attributes["rel"].value == "nofollow next" }.first.attributes["href"].value rescue nil
        paginations += 1
        this_step = 0
        puts "***Shifted to next page. #{paginations} total paginations so far...***"
      end
    end
    return @sample
  end
  
  def pull_thread(url, full=true, retry_threshold=10)
    retries = 0
    begin
      sleep(2) #self-enforced rate limiting as per reddit's desire to not get hammered by API scrapes
      return JSON.parse(open(url+".json?limit=500").read)
    rescue
      if retries < retry_threshold
        retries+=1
        retry
      else
        return []
      end
    end
  end
  
  def collapse_thread(raw_thread_data)
    if !raw_thread_data.empty?
      post, comments = raw_thread_data
      comments = Hashie::Mash[comments].data.children
      post = Hashie::Mash[post].data.children.first.data
      return flatten_comment_tree(comments, []).unshift(post_to_normalized_comment(post))
    else
      return []
    end
  end
  
  def flatten_comment_tree(comments, found_comments)
      comments.each do |comment|
        children = comment && comment.data && comment.data.replies && comment.data.replies != "" && comment.data.replies.data && comment.data.replies.data.children || nil
        normalized_comment = comment_to_normalized_comment(comment.data)
        found_comments << normalized_comment if !normalized_comment.created.nil?
        if children
          children.each do |child_comment|
            normalized_comment = comment_to_normalized_comment(child_comment.data)
            found_comments << normalized_comment if !normalized_comment.created.nil?
            found_comments.uniq!
            puts found_comments.length
            found_comments = (found_comments+flatten_comment_tree(child_comment.data.replies.data.children, found_comments)).uniq! if child_comment && child_comment.data && child_comment.data.replies && child_comment.data.replies != "" && child_comment.data.replies.data && child_comment.data.replies.data.children
          end
        end
      end
    puts found_comments.length
    return found_comments
  end

  def flatten_comment_tree_full(comments, found_comments)
    previous_comments = []
    while previous_comments != comments
      comments.each do |comment|
        children = comment && comment.data && comment.data.replies && comment.data.replies != "" && comment.data.replies.data && comment.data.replies.data.children || nil
        previous_children = []
        found_comments << comment_to_normalized_comment(comment.data)
        if comment.kind == "more"
          debugger
          comments+=Hashie::Mash[pull_thread(self.current_post_url+"/"+comment.data.name).last].data.children
          comments-=[comment]
        end
        if children
          while previous_children != children
            children.each do |child_comment|
              found_comments << comment_to_normalized_comment(child_comment.data)
              found_comments.uniq!
              if child_comment.kind == "more"
                children+=Hashie::Mash[pull_thread(self.current_post_url+"/"+child_comment.data.name).last].data.children
                children-=[child_comment]
              end
              puts found_comments.length
              found_comments = (found_comments+flatten_comment_tree(child_comment.data.replies.data.children, found_comments)).uniq! if child_comment && child_comment.data && child_comment.data.replies && child_comment.data.replies != "" && child_comment.data.replies.data && child_comment.data.replies.data.children
            end
            previous_children = children
          end
        end
      end
      previous_comments = comments
    end
    puts found_comments.length
    return found_comments
  end
  
  def post_to_normalized_comment(post)
    normalized_comment = Hashie::Mash[]
    normalized_comment.author
    normalized_comment.author_flair_css_class = post.author_flair_css_class
    normalized_comment.author_flair_text
    normalized_comment.body = post.selftext
    normalized_comment.body_html = post.selftext_html    
    normalized_comment.created = Time.at(post.created) 
    normalized_comment.created_utc = Time.at(post.created_utc)
    normalized_comment.domain = post.domain
    normalized_comment.downs = post.downs
    normalized_comment.hidden = post.hidden
    normalized_comment.reddit_id = post.id
    normalized_comment.levenshtein = post.levenshtein
    normalized_comment.likes = post.likes
    normalized_comment.link_id = post.name
    normalized_comment.name = post.name
    normalized_comment.num_comments = post.num_comments
    normalized_comment.over_18 = post.over_18
    normalized_comment.parent_id = nil
    normalized_comment.permalink = post.permalink
    normalized_comment.score = post.score
    normalized_comment.subreddit = post.subreddit
    normalized_comment.subreddit_id = post.subreddit_id
    normalized_comment.title = post.title
    normalized_comment.ups = post.ups
    normalized_comment.url = post.url
    normalized_comment.created_utc.nil? ? Hashie::Mash[] : normalized_comment
  end
  
  def comment_to_normalized_comment(comment)
    normalized_comment = Hashie::Mash[]
    if comment.keys.length != 2
      normalized_comment.author = comment.author
      normalized_comment.author_flair_css_class = comment.author_flair_css_class
      normalized_comment.author_flair_text = comment.author_flair_text
      normalized_comment.body = comment.body
      normalized_comment.body_html = comment.body_html
      normalized_comment.created = Time.at(comment.created)
      normalized_comment.created_utc = Time.at(comment.created_utc)
      normalized_comment.domain = nil
      normalized_comment.downs = comment.downs
      normalized_comment.hidden = nil
      normalized_comment.reddit_id = comment.id
      normalized_comment.levenshtein = comment.levenshtein
      normalized_comment.likes = comment.likes
      normalized_comment.link_id = comment.link_id
      normalized_comment.name = comment.name
      normalized_comment.num_comments = comment.num_comments
      normalized_comment.over_18 = comment.over_18
      normalized_comment.parent_id = comment.parent_id
      normalized_comment.permalink = nil
      normalized_comment.score = comment.ups-comment.downs
      normalized_comment.subreddit = comment.subreddit
      normalized_comment.subreddit_id = comment.subreddit_id
      normalized_comment.title = ""
      normalized_comment.ups = comment.ups
      normalized_comment.url = nil
    end
    normalized_comment.created_utc.nil? ? Hashie::Mash[] : normalized_comment
  end
  
  def comment_keys
    return ["author", "author_flair_css_class", "author_flair_text", "body", "body_html", "created", "created_utc", "downs", "id", "levenshtein", "likes", "link_id", "name", "parent_id", "subreddit", "subreddit_id", "ups"]
  end
  
  def post_keys
    return ["author", "author_flair_css_class", "author_flair_text", "clicked", "created", "created_utc", "domain", "downs", "hidden", "id", "is_self", "levenshtein", "likes", "media", "media_embed", "name", "num_comments", "over_18", "permalink", "saved", "score", "selftext", "selftext_html", "subreddit", "subreddit_id", "thumbnail", "title", "ups", "url"]
  end
  
  def self.run_test
    @sample = Sample.new
    @sample.created_at = Time.now
    @sample.save!
    @hitler_test = ThreadSample.new
    @hitler_test.collect_sample
    @hitler_test.current_post_url = @hitler_test.sample.first
    thread = @hitler_test.pull_thread(@hitler_test.sample.first)
    collapsed_thread = @hitler_test.collapse_thread(thread)
    puts collapsed_thread.length

    @comment_sets = []
    @hitler_test.sample.each do |url|
      @hitler_test.current_post_url = url
      comments = @hitler_test.collapse_thread(@hitler_test.pull_thread(url))
      @comment_sets << comments
    end
    @comment_sets.flatten.collect{|h| h.sample_id = @sample.id}
    @comment_sets.each do |set|
      Comment.save_all(set.collect{|c| c.to_hash})
    end
    ttgs = []
    ctgs = []
    Comment.all(:parent_id => nil, :sample_id => @sample.id).each do |post|
      stats = post.resolve_stats
      godwin = Godwin.new
      godwin.comment_id = stats[:first_godwin_id]
      godwin.sample_id = @sample.id
      godwin.godwin = stats[:first_godwin_id] != 0
      godwin.save!
      ttgs << stats[:time_to_godwin]
      ctgs << stats[:count_to_godwin]
    end
    @sample.finalize_properties({:ttgs => ttgs, :ctgs => ctgs})
    @sample.save!
  end
end
ThreadSample.run_test
#posts = Comment.all(:parent_id => nil)
#ttgs = []
#ctgs = []
#posts.all.each do |post|
#      stats = post.resolve_stats
#       godwin = Godwin.new
#       godwin.comment_id = stats[:first_godwin_id]
#       godwin.sample_id = @sample.id
#       godwin.godwin = stats[:first_godwin_id] != 0
#       godwin.save!
#       ttgs << stats[:time_to_godwin]
#      ctgs << stats[:count_to_godwin]
#end
