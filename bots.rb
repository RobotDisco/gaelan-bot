require 'date'
require 'httparty'
require 'json'

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
    @pesters_left = 5
  end
end

class DevoBot < Ebooks::Bot
  def configure
    self.consumer_key = ENV['DEVOBOT_CONSUMER_KEY']
    self.consumer_secret = ENV['DEVOBOT_CONSUMER_SECRET']
  end

  def what_we_are(wordlist)
    <<-EOF.gsub(/^\s+\|/, '')
    |Q: Are We Not Men?
    |A: We are #{wordlist.sample.strip.upcase}!
    EOF
  end

  def on_startup
    file = '/usr/share/dict/web2'
    wordlist = File.open(file).readlines

    scheduler.every '1h' do
        tweet what_we_are(wordlist)
    end
  end
end

class CassiniBot < Ebooks::Bot
  def end_date
    cassini_ends = Date.new(2017,9,15)
    today = Date.today

    cassini_ends - today
  end

  def configure
    self.consumer_key = ENV['CASSINI_CONSUMER_KEY']
    self.consumer_secret = ENV['CASSINI_CONSUMER_SECRET']
  end

  def say_nooo
    # We have about 126 characters to play with
    num_os = Random.rand(125) + 1
    "N#{'O' * num_os} Cassini can't be ending"
  end

  def say_end_date
      "Only #{end_date.floor} days until the Cassini mission ends :( :( :("
  end

  def say_dying_breath()
    num_os = end_date.floor
    num_dots = 140 - end_date
    final_breath = 'O'.times(num_os) + '.'.times(num_dots)
    final_breath[0] = 'N'
  end

  def on_startup
    scheduler.every '1h' do
      return unless end_date > 140
      if (Random.rand <= 0.25)
        if (Random.rand <= 0.125)
            tweet say_end_date()
        else
            tweet say_nooo()
        end
      end
    end
    scheduler.every '6h' do
      return unless end_date <= 140
      tweet say_dying_breath()
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
    self.consumer_key = ENV['TWITTER_CONSUMER_KEY'] # Your app consumer key
    self.consumer_secret = ENV['TWITTER_CONSUMER_SECRET'] # Your app consumer secret
    @lyrics_key = ENV['TWITTER_MUSIXMATCH_KEY'] # Key for accessing lyrics API

    @singer_influences = [
      538, # Jacques Brel
      13182, # Scott Walker
      12426703, # Grimes
    ]

    # Users to block instead of interacting with
    self.blacklist = ['cmcbot', 'megbeepboop']

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 1..900
  end

  def lyrics_api_base(suffix)
      'http://api.musixmatch.com/ws/1.1/' + suffix 
  end

  def sing_song
      artist_pick = @singer_influences.sample

      track_query = {
        :query => {
          apikey: @lyrics_key,
          f_has_lyrics: '1',
          f_artist_id: artist_pick,
          page_size: 100
        }
      }
      tracks = HTTParty.get(self.lyrics_api_base('track.search'), track_query).body
      tracks = JSON.parse(tracks)['message']['body']['track_list'].map do |e|
          [e['track']['track_id'], e['track']['track_share_url']]
      end
      track_id = tracks.sample
      
      lyric_query = {
        :query => {
          apikey: @lyrics_key,
          track_id: track_id[0]
        }
      }
      snippet = HTTParty.get(self.lyrics_api_base('track.snippet.get'), lyric_query).body

      raw = JSON.parse(snippet)
      snippet = raw['message']['body']['snippet']['snippet_body'].strip

      if snippet.size > 138
          raw = snippet[0...135]
          raw << "..."
      end
      
      "\u266A#{snippet}\u266A - #{track_id[1]}"
  end

  def on_startup
    @model = Ebooks::Model.load('model/NaleagDeco.model')
    @top200 = @model.keywords
    @userinfo = {}

    scheduler.every '1h' do
      # Tweet something every hour
      # See https://github.com/jmettraux/rufus-scheduler
      # tweet("hi")
      # pictweet("hi", "cuteselfie.jpg")
      if (Random.rand <= 0.125)
        tweet sing_song()
      else
        tweet @model.make_statement
      end
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
  bot.access_token = ENV['TWITTER_ACCESS_TOKEN'] # Token connecting the app to this account
  bot.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET'] # Secret connecting the app to this account
end

CassiniBot.new("CassiniNooo") do |bot|
  bot.access_token = ENV['CASSINI_ACCESS_TOKEN']
  bot.access_token_secret =  ENV['CASSINI_ACCESS_TOKEN_SECRET']
end

DevoBot.new("EveryDevo") do |bot|
  bot.access_token = ENV['DEVOBOT_ACCESS_TOKEN']
  bot.access_token_secret = ENV['DEVOBOT_ACCESS_TOKEN_SECRET']
end
