# encoding: UTF-8
$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'socket'
require 'cgi'
#require_relative 'shosai/serve'
require_relative 'kanji/serve'
require_relative 'audio/serve'
require_relative 'vocab/serve'


server = TCPServer.new('127.0.0.1', 80)

puts "Listening on port 80..."

log = File.open("log.txt",'w')

TICK = 0.1

#GC_PERIOD = 60*5
#gc_timer = 0


loop do

  select = IO.select([server], nil, nil, TICK)

  Audio.watchdog_tick

#  gc_timer += TICK
#  if gc_timer > GC_PERIOD
#    gc_timer = 0
#    puts
#    puts '-[ Running GC ]----------------------------------------------------------------'
#    puts `tasklist.exe`.split("\n").select {|line| line.include? "#{Process.pid} Console"}
#    GC.start
#    puts `tasklist.exe`.split("\n").select {|line| line.include? "#{Process.pid} Console"}
#    puts '-------------------------------------------------------------------------------'
#    puts
#  end

  next if select == nil


  begin
    s = server.accept_nonblock
    next if s == nil

    req = s.recv(4096).force_encoding('utf-8')
    log.puts req
    log.flush

    if m = req.match(/^POST \/(.+) HTTP\/1\.1.+Content-Length: \d+.{4}(.+)$/m)
      method, url, args = :post, m[1], m[2]
    elsif m = req.match(/^GET \/(.+) HTTP\/1\.1/)
      method, url, args = :get, m[1], nil
    else
      next
    end

    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S.%6N')}] #{method.to_s.upcase} #{url} #{args}"

    if method == :get && url.index("kanji/") == 0
      Kanji.serve(url, s)
    elsif method == :get && url.index("audio/") == 0
      Audio.serve(url, s)
    elsif method == :get && url.index("vocab_DE") == 0
      Vocab.serve(url, s)
    end

  rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR, Errno::EWOULDBLOCK
    puts "exception #{Time.now}"
    retry

  ensure
    s.close
  end

end

log.close
