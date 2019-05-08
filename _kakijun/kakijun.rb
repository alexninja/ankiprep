# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')
$GIFDIR = 'D:/Japanese/_dict/gif'
SLEEP = 0

require 'misc/utf8'
require 'misc/utf16'
require_relative 'fetch_gif'

#----------------------------------------------------------------------------------------

Net::HTTP.SOCKSProxy('127.0.0.1', 9050).start('check.torproject.org') do |http|
  res = http.get('/')
  if res.class == Net::HTTPOK
    puts res.body[/Your IP address appears to be: <b>(.+)<\/b>/]
  else
    puts "some Tor error: #{res.class}"
    exit(1)
  end
end

#----------------------------------------------------------------------------------------

$report = File.open('report.html','w')

def $report.<<(s)
  puts s
  flush
end

def $report.log_kanji(k, i, total_size, color, message = nil)
  utf16 = k.utf16_code.upcase
  imgname_static = "gif/u#{utf16}-static.gif"
  imgname = "gif/u#{utf16}.gif"

  $report << "[#{i+1}/#{total_size}]<br><font size=40 color=#{color}>#{k}</font><br>"
  $report << "Unicode: #{utf16}<br>"
  $report << "<b>#{message}</b><br>" if message
  $report << "<img src=#{imgname_static} width=200 height=200>"
#  $report << "<img src=#{imgname} width=200 height=200><br>"
  $report << "#{File.size(imgname)} bytes<br>" if File.exist?(imgname)
  $report << '<hr>'
end

#----------------------------------------------------------------------------------------

$all = Utf8.readlines('kanji_all.txt').join.chars.to_a

$done = []
if File.exist?('gif') and File.directory?('gif')
  Dir['gif/u????.gif'].each do |file|
    $done << file.split('/').last.split('.')[0][1..4].charfrom_utf16
  end
end

$toget = $all - $done


$report << '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">'

# report existing kanji

$report << "<b>#{$done.size}</b> already fetched (out of #{$all.size} in kanji_all.txt):<br>"
$report << $done.join
$report << '<hr>'

$done.each_with_index do |k,i|
  $report.log_kanji(k, i, $done.size, 'blue')
end

# report new kanji as we get them

$report << "<b>#{$toget.size}</b> kanji to fetch:<br>"
$report << $toget.join
$report << '<hr>'

$toget.each_with_index do |k,i|
  puts
  puts '---------------------------------------------------------'
  puts "[#{i+1}/#{$toget.size}]: sleeping #{SLEEP} seconds..."
  sleep SLEEP

  message = fetch_gif(k)
  $report.log_kanji(k, i, $toget.size, 'red', message)
  puts "\n[ #{message} ]"
end

