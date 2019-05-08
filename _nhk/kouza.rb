# download stuff from http://www.nhk.or.jp/kokokoza/index.html
# parameter: link to page, e.g. http://www.nhk.or.jp/kokokoza/radio/r2_kokugo/archive/chapter069.html

require 'net/http'
require 'uri'

def http_get(url)
  uri = URI.parse(url)
  res = Net::HTTP.start(uri.host, uri.port) {|http| http.get uri.path}
  res.body
end

abort("What URL?") unless ARGV.size == 1

raise unless m = http_get(ARGV[0]).match(/<noscript><a href=\"(.*)\" target=\"_blank\">/)
puts "--> #{m[1]}"

raise unless m = http_get(m[1]).match(/<Ref href=\"(.*)\" \/>/)
puts "--> #{m[1]}"

outfile = m[1].split('/')[-2..-1].join('_')
puts "--> #{outfile}"
puts

cmdline = "D:/Tools/mplayer/mplayer.exe -dumpstream -dumpfile #{outfile} #{m[1]}"
puts "[ running #{cmdline} ]"
puts
system(cmdline)
