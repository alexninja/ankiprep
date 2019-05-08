#!/usr/local/bin/ruby

require "socket"

Dict = [
  ["dependant", "dependent"],
  ["dependance", "dependence"],
  ["dependancy", "dependency"],
  ["independance", "independence"],
  ["independantly", "independently"],
  ["irregardless", "regardless"],
  ["surviver", "survivor"],
  ["low and behold", "lo and behold"],
  ["artical", "article"],
  ["imposter","impostor"],
  ["imposters","impostors"],
  ["inheritence","inheritance"],
  ["definate","definite"],
  ["definately","definitely"],
  ["exercize","exercise"],
  ["exercized","exercised"],
  ["rediculous", "ridiculous"]
].
  sort_by {|pair| pair[0].size}.reverse



# The irc class, which talks to the server and holds the main event loop
class IRC
    def initialize(server, port, nick, channel)
        @server = server
        @port = port
        @nick = nick
        @channel = channel
    end
    def send(s)
        # Send a message to the irc server and print it to the screen
        puts "--> #{s}"
        @irc.send "#{s}\n", 0 
    end
    def connect()
        # Connect to the IRC server
        @irc = TCPSocket.open(@server, @port)
        send "USER lol lol lol :lol lol"
        send "NICK #{@nick}"
        send "JOIN #{@channel}"
    end
    def handle_server_input(s)
        # This isn't at all efficient, but it shows what we can do with Ruby
        # (Dave Thomas calls this construct "a multiway if on steroids")
        case s.strip
            when /^PING :(.+)$/i
                puts "[ Server ping ]"
                send "PONG :#{$1}"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
                puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001PING #{$4}\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
                puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/i
                puts "<#{$1}> #{$5}"
                Dict.each do |bad,good|
                  if $5.downcase.include? bad
                    send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{(($4==@nick)?"":$1+", ")}surely you mean \"#{good}\"".gsub("ohai","0hai")
                    break
                  end
                end
            else
                puts s
        end
    end
    def main_loop()
        # Just keep on truckin' until we disconnect
        while true
            ready = select([@irc], nil, nil, nil)
            next if !ready
            if ready[0][0] == @irc then
                return if @irc.eof
                s = @irc.gets
                handle_server_input(s)
            end
        end
    end
end

# The main program
# If we get an exception, then print it out and keep going (we do NOT want
# to disconnect unexpectedly!)
irc = IRC.new('irc.inet.tele.dk', 6667, 'Archibald', '#C++')
irc.connect()
begin
    irc.main_loop()
rescue Interrupt
rescue Exception => detail
    puts detail.message()
    print detail.backtrace.join("\n")
    retry
end
