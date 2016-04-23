require 'date'

require 'twitter_ebooks'
require 'twitter_ebooks/model'

require_relative 'config'

# Information about a particular Twitter user we know
class UserInfo
  attr_reader :username

  # @return [Integer] how many times we can pester this user unprompted
  attr_accessor :pesters_left

  # @param username [String]
  def initialize(username)
    @username = username
    @pesters_left = 5
  end
end


class CassiniBot < Ebooks::Bot
  def configure
    self.consumer_key = CONFIG['CASSINI_CONSUMER_KEY']
    self.consumer_secret = CONFIG['CASSINI_CONSUMER_SECRET']
  end

  def say_nooo
    # We have about 126 characters to play with
    num_os = Random.rand(125) + 1
    "N#{'O' * num_os} Cassini can't be ending"
  end

  def say_end_date
    cassini_ends = Date.new(2017,9,15)
    today = Date.today
    difference = cassini_ends - today

    "Only #{difference.floor} days until the Cassini mission ends :( :( :("

  def on_startup
    scheduler.every '1h' do
      if (Random.rand <= 0.25)
        if (Random.rand <= 0.125
            tweet say_end_date()
        else
            tweet say_nooo()
        end
      end
    end
  end
end

# This is an example bot definition with event handlers commented out
# You can define and instantiate as many bots as you like

class MyBot < Ebooks::Bot
  # Configuration here applies to all MyBots
  def configure
    # Consumer details come from registering an app at https://dev.twitter.com/
    # Once you have consumer details, use "ebooks auth" for new access tokens
    self.consumer_key = CONFIG['TWITTER_CONSUMER_KEY'] # Your app consumer key
    self.consumer_secret = CONFIG['TWITTER_CONSUMER_SECRET'] # Your app consumer secret

    # Users to block instead of interacting with
    self.blacklist = ['cmcbot', 'megbeepboop']

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 1..900
  end

  def on_startup
    @model = Ebooks::Model.load('model/MentatMode.model')
    @top200 = @model.keywords
    @userinfo = {}

    scheduler.every '1h' do
      # Tweet something every hour
      # See https://github.com/jmettraux/rufus-scheduler
      # tweet("hi")
      # pictweet("hi", "cuteselfie.jpg")
      tweet @model.make_statement
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
  bot.access_token = CONFIG['TWITTER_ACCESS_TOKEN'] # Token connecting the app to this account
  bot.access_token_secret = CONFIG['TWITTER_ACCESS_TOKEN_SECRET'] # Secret connecting the app to this account
end

CassiniBot.new("CassiniNooo") do |bot|
  bot.access_token = CONFIG['CASSINI_ACCESS_TOKEN']
  bot.access_token_secret =  CONFIG['CASSINI_ACCESS_TOKEN_SECRET']
end
