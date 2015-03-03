require 'twitter_ebooks'
require 'twitter_ebooks/model'

# Information about a particular Twitter user we know
class UserInfo
  attr_reader :username

  # @return [Integer] how many times we can pester this user unprompted
  attr_accessor :pesters_left

  # @param username [String]
  def initialize(username)
    @username = username
    @pesters_left = 10
  end
end

# This is an example bot definition with event handlers commented out
# You can define and instantiate as many bots as you like

class MyBot < Ebooks::Bot
  # Configuration here applies to all MyBots
  def configure
    # Consumer details come from registering an app at https://dev.twitter.com/
    # Once you have consumer details, use "ebooks auth" for new access tokens
    self.consumer_key = ENV['TWITTER_CONSUMER_KEY'] # Your app consumer key
    self.consumer_secret = ENV['TWITTER_CONSUMER_SECRET'] # Your app consumer secret

    # Users to block instead of interacting with
    self.blacklist = ['cmcbot']

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 1..900
  end

  def on_startup
    @model = Ebooks::Model.load('model/MentatMode.model')
    @top200 = @model.keywords

    scheduler.every '1h' do
      # Tweet something every hour
      # See https://github.com/jmettraux/rufus-scheduler
      # tweet("hi")
      # pictweet("hi", "cuteselfie.jpg")
      tweet @model.make_statement
    end

    scheduler.every '0 0 * * *' do
      tweet "Hi, I have learned to talk with my friends :D Please tell @MentatMode if I accidentally upset you, I'm sorry :("
    end
  end

  def on_message(dm)
    # Reply to a DM
    # reply(dm, "secret secrets")
  end

  def on_follow(user)
    # Follow a user back
    # follow(user.screen_name)
  end

  def on_mention(tweet)
    # Reply to a mention
    # reply(tweet, "oh hullo")

    # Become more inclined to pester a user when they talk to us
    userinfo(tweet.user.screen_name).pesters_left += 1

    delay do
      reply(tweet, @model.make_response(meta(tweet).mentionless,
                                        meta(tweet).limit))
    end
  end

  def on_timeline(tweet)
    # Reply to a tweet in the bot's timeline
    # reply(tweet, "nice tweet")

    return if tweet.retweeted_status?
    return unless can_pester?(tweet.user.screen_name)

    tokens = Ebooks::NLP.tokenize(tweet.text)

    interesting = tokens.find { |t| @top200.include?(t.downcase) }

    delay do
      if interesting
        if rand < 0.001
          userinfo(tweet.user.screen_name).pesters_left -= 1
          reply(tweet, model.make_response(meta(tweet).mentionless,
                                           meta(tweet).limit))
        end
      end
    end
  end

  # Find information we've collected about a user
  # @param username [String]
  # @return [Ebooks::UserInfo]
  def userinfo(username)
    @userinfo[username] ||= UserInfo.new(username)
  end

  # Check if we're allowed to send unprompted tweets to a user
  # @param username [String]
  # @return [Boolean]
  def can_pester?(username)
    userinfo(username).pesters_left > 0
  end

  def on_favorite(user, tweet)
    # Follow user who just favorited bot's tweet
    # follow(user.screen_name)
  end
end

# Make a MyBot and attach it to an account
MyBot.new("gaelan_bot") do |bot|
  bot.access_token = ENV['TWITTER_ACCESS_TOKEN'] # Token connecting the app to this account
  bot.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET'] # Secret connecting the app to this account
end
