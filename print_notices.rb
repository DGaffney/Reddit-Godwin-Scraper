load "run.rb"
users = Godwin.all(:comment_id.not => 0).collect{|x| Comment.first(:id => x.comment_id)}.compact.uniq.collect{|x| x}

f = File.open("notices.txt", "w")
users.each do |user|
  f.write("Hello,\r\n My name is Devin Gaffney, and I am a Master's candidate at Oxford University's Internet Institute. That's right, there is a place where you can study the Internet as an academic concentration. Anyways, I am working on a paper currently that is focused on calculating the entropy of forum threads, where we define the entropy to be the moment that someone invokes either Hitler or the Nazis.

This is colloquially called Godwin's law, and you can read more about it here: http://en.wikipedia.org/wiki/Godwin's_law. 

Anyways, as Reddit's forum data is available through an API, I wrote a script that collected the data of many, many threads over the course of the last week or so. In total, I have collected approximately 300,000 comments across 5,000 threads. Of all this data, I couldn't help but notice that you were the source of one of the 108 'hits' on Godwin's law, by being the first (based on time) to post something mentioning either Hitler or the Nazis. Your specific case is provided here: http://www.reddit.com#{user.parent.permalink}#{user.reddit_id}.

I have found 108 total 'godwinned' threads, so, as you may have detected by now, this message is a standard one I am using to mail everyone. The reason I'm contacting you in the first place is, seeing you invoked the law, I want to survey you about your reasons for doing so (whether in seriousness or in jest), in the hope to measure the extent to which this actually happens online, or if this is purely just a joke. By participating in this, you will be helping, at least in a very narrow and small way, help nerds like us get to the core of how people behave online, which may or may not matter.

Obviously, I'm going to keep your identity between you and me and the data - you'll never be pointed out in any final form of the information, and if anything, it will just determine the precise y-value of a dot in a histogram. Now the fun part: If you do fill out the survey, I will be entering your name into a pool, of which I will choose one respondent, to receive the gift of gold - Reddit Gold - for 12 months. If you do already have this, then I will mail you or send you something digital of equal or lesser worth. Either way, I would love to have your input on this project. If you do have a few minutes to spare in your day, please visit this URL to fill out the survey:

So with that, if you're feeling up to it, you can find the survey here: https://docs.google.com/spreadsheet/viewform?formkey=dEE3M3Btcno5MndmX1BWWGExRVFGOGc6MQ\n\n\n\n")
end
