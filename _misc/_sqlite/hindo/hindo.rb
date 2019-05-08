#!/usr/bin/env ruby1.9
# encoding: UTF-8

require 'term/ansicolor'
require 'oauth'
require 'MeCab'
require 'yaml'
require 'getoptlong'
require 'kconv'
require 'twitter'

class Counter
    attr_accessor :id

    def initialize(words, word_filter, users_to_ignore)
        @word_filter = word_filter
        @words = words
        @tagger = Tagger.new
        @tweet_log = TweetsLog.new
        @users_to_ignore = users_to_ignore

        @id = @words.load
    end

    def save_data()
        @tweet_log.close()
        @words.save(@id)
    end

    def count_words_in(tweets)
        $log.info "Counting words"
        tweets.each {|tweet| count tweet }
    end

    def count(tweet)
        @id = [@id, tweet.id].max

        if @users_to_ignore.include? tweet.user.screen_name then
            puts "Skipping tweet from #{tweet.user.name}"
            return
        end

        @tweet_log.log Tweet.new(tweet.id, tweet.user.name, tweet.text)
        $stdout.puts "#{tweet.id}, #{green(tweet.user.name)}, #{tweet.text[0..10]}..."

        @tagger.words(tweet.text).each do |word|
            if @word_filter.collectable? word.kanji then
                @words.add(word)
            end
        end
    end

end

class Opts
    attr_accessor :daemon
	attr_accessor :abort
	attr_accessor :verbose
    
    def initialize()
        opts = GetoptLong.new(
            ['--daemon', '-d', GetoptLong::NO_ARGUMENT],
            ['--help', '-h', GetoptLong::NO_ARGUMENT],
            ['--verbose', '-v', GetoptLong::NO_ARGUMENT]
        )

        @daemon = false

        opts.each do |opt, arg|
            case opt
                when '--help'
                    puts "help!"
					@abort = true
                when '--daemon'
                    @daemon = true
                when '--verbose'
                    @verbose = true
            end
        end
    end
end




Settings = Struct.new(:oauth_token_secret, :oauth_token, :time_to_wait, :users_to_ignore, :words_to_ignore, :kanji_db, :phrase_db, :use_kana) do
    def save()
        puts "Saving settings to 'settings.yaml'"
        File.open( 'settings.yaml', 'w' ) do |out|
            YAML.dump( self, out )
        end
    end
end

def load_settings()
    settings = NIL
    File.open( 'settings.yaml' ) { |yf| settings = YAML::load( yf ) }
    return settings
end


class SleepLoop
	attr_accessor :run

	def initialize(time_to_wait)
		@time_to_wait = time_to_wait
		@run = true
		
                Signal.trap( "SIGINT") do
                        puts "Terminating..."
                        @run = false
                end
	end

	def light_sleep()
		(@time_to_wait * 60).times do
			if not @run then
				break
			end

			begin
				sleep 1
			rescue 
				@run = false
			end
		end
	end
	
	def loop(block)
		while @run do 
			block.call
			light_sleep
		end
	end 

end

def sleep_loop(time, block)
    SleepLoop.new(time).loop block
end


class Word
    attr_accessor :kanji
    attr_accessor :kana
    attr_accessor :key
    attr_accessor :type

    def self.make_key(kanji, kana)
        return "#{kanji}:#{kana}"
    end

    def initialize(kanji, kana, type)
        @kanji = kanji
        @kana = kana
        @type = type
        @key = Word.make_key(kanji, kana)
    end

end

class Tagger
    def initialize()
        @tagger = MeCab::Tagger.new("-Ochasen")
    end
    def words(text)
        words = Array.new
        node = @tagger.parseToNode(text)
        while node
            word = node.surface.toutf8
            kana = node.feature.toutf8.split(",")[-1]
            type = node.feature.toutf8.split(",")[0]

            if not words.empty? and type == "助動詞" and words.last.type == "動詞" then
                words.last.kanji += word
                words.last.kana += kana
            else
                if not node.surface == "" then
                    words << Word.new(word, kana, type)
                end
            end

            node = node.next
        end

        return words
    end
end


class Tsuitta
    def initialize(settings, client = Twitter::Client)
        consumer_key="UB3fjEznQ8CoZNmDeVGnIA"
        consumer_secret="sqkEpydjdDYJmdTz5fPozLy9MhucUw8JK2MBoxovg"

        if not authorized?(settings) then
            consumer = OAuth::Consumer.new(
                consumer_key,
                consumer_secret,
                {:site => 'http://twitter.com'}
            )

            request_token = consumer.get_request_token

            puts "Open this url and copy the number from the page"
            puts request_token.authorize_url

            puts "Enter pin: "

            pin = gets.chomp.strip

            access_token = request_token.get_access_token(:oauth_verifier => pin)

            oauth_token = access_token.token
            oauth_token_secret = access_token.secret

            settings.save
        else
            #puts "Using saved key"
            oauth_token = settings.oauth_token
            oauth_token_secret = settings.oauth_token_secret
        end

        Twitter.configure do |config|
            config.consumer_key = consumer_key
            config.consumer_secret =  consumer_secret
            config.oauth_token = oauth_token
            config.oauth_token_secret = oauth_token_secret
        end

        @client = client.new
    end

    def authorized?(settings)
        return (not (settings.oauth_token.nil? or settings.oauth_token_secret.nil?))
    end

    def get(since_id)
        options={:count=>190,:since_id=>since_id}

        begin
            return @client.home_timeline(options)
        rescue => e
            $log.error e.message
	    begin
                return @client.home_timeline(options)
            rescue
                raise TweetError
            end
        end
    end
end

class TweetError < Exception
end


include Term::ANSIColor

class TweetsFile
    TWEETS_FILE = "tweets.txt"
end

class TweetsSearch < TweetsFile
    def initialize(file=File)
        @file = file.new(TWEETS_FILE)
    end

    def search(word)
        results = []

        @file.readlines.select{|l|l=~/#{word}/}.each do |line|
                results << line.gsub(word, red(word))
        end

        return results
    end

end

Tweet = Struct.new(:id, :user, :text)

class TweetsLog < TweetsFile

    def initialize(file=File)
        @file = file.new(TWEETS_FILE, "a")
    end

    def log(tweet)
        @file.puts "#{tweet.id}|#{tweet.user}|#{tweet.text}"
    end

    def close()
        @file.close
    end
end

class WordFilter

    def initialize(words_to_ignore)
        @words_to_ignore = words_to_ignore
        $log.debug "Ignore #{words_to_ignore}"
    end

    def collectable?(word)
        if @words_to_ignore.include? word then
            return false
        end
        if word.to_f > 0 then
            return false
        end
        japanese_word = /^(\p{Hiragana}|\p{Katakana}|\p{Han}|[ー・])+$/
        if not japanese_word =~ word then
            return false
        end
        return true
    end
end

class Words < Hash
    attr_accessor :file_name

    def initialize(settings, word_filter)
        @word_filter = word_filter
        @settings = settings
        if settings.use_kana then
            @file_name = 'kdata.txt'
        else
            @file_name = 'data.txt'
        end
    end

    def save(id)
        $log.debug "Saving data"
        data = File.new(@file_name, "w")
        data.puts id
        sort {|a,b| b[1]<=>a[1]}.each {|a|data.puts "#{a[0]},#{a[1]}\n"}
        data.close()
    end

    def load()
        $log.debug "Loading data"
        if File.exists?(@file_name) then
            data = IO.readlines @file_name

            id = data[0].to_i

            if data.length > 1 then
                data[1..-1].each {|line|
                    d = line.split(",")
                    if @word_filter.collectable?(d[0]) then
                        self[d[0]] = d[1].to_i
                    end
                }
            end
        else
            id = 10
        end

        return id
    end

    def add(word)
        if @settings.use_kana then
            key = word.key
        else
            key = word.kanji
        end

        if has_key? key then
            self[key] = self[key] + 1
        else
            self[key] = 1
        end
    end
end
