# downloads the flv video from an article on http://www3.nhk.or.jp/news/
# example usage:
# nhk.rb http://www3.nhk.or.jp/news/html/20110809/t10014789031000.html

require 'net/http'
require 'uri'


def http_get(url)
  uri = URI.parse(url)
  res = Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path) }
  res.body
end


url = ARGV.shift || abort("what URL?")

body = http_get(url)


if m = body.match(/<div id="news_video">(.+)<\/div>/)

  news_video = m[1]

  puts "found! #{news_video}\n\n"
  puts "running D:/Tools/rtmpdump-2.3/rtmpdump.exe -r rtmp://flv.nhk.or.jp/ondemand/flv/news/#{news_video} -o #{news_video}.flv\n\n"
  `D:/Tools/rtmpdump-2.3/rtmpdump.exe -r rtmp://flv.nhk.or.jp/ondemand/flv/news/#{news_video} -o #{news_video}.flv`
  puts "\nDownloaded #{news_video}.flv\n"

  css = '<style type="text/css">'
  body.scan(/<link.*href=\"(.+)\.css".+>/).flatten.each do |f|
    css += http_get( url.split('/')[0..-2].join('/') + '/' + f + '.css' )
  end
  css += '</style>'
  File.open(news_video+'.html','w') do |f|
    f.write body.gsub(/<script.*<\/script>/,'').gsub("../../css/","css/").sub('</head>',css)
  end
  puts "\nSaved #{news_video}.html\n"

else

  puts '<div id="news_video">...<\/div> not found in HTML'

end
