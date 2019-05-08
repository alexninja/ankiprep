$KCODE = 'U'

require '../libs/kanji'
require '../libs/kana'
require '../libs/misc/moji'
require '../libs/misc/utf8'
require '../libs/misc/progress'

Kanji.load('D:/Japanese/dict/edict/kanjidic.utf8')

s = []
p = Progress.new(Kanji.size)
f = File.open('a.html','w')
i = 0

Kanji.each_kanji do |k|
  onyomi = Kanji.yomi(k).select {|yomi| yomi.moji.all? {|m| Kana.katakana?(m)}}
  #f.puts "#{k}#{Utf8::Space}#{onyomi.join(Utf8::Space)}<br>\n"
  s << [k, onyomi]
  p.tick(i)
  i += 1
end

p.clear

total = s.inject(0) {|t,pair| t += pair[1].size}
f.puts "#{total} total onyomi<br>\n"

h = Hash.new(0)
s.map {|pair| h[pair[1].size]+=1}
h.keys.max.downto(0) {|i| f.puts "#{h[i]} kanji with #{i} onyomi<br>\n"}
f.puts "<br>\n"


s.sort_by {|pair| pair[1].size}.reverse.each do |pair|
  k, onyomi = pair
  f.puts "#{k}#{Utf8::Space}#{onyomi.join(Utf8::Space)}#{Utf8::Space}(#{onyomi.size})<br>\n"
end

f.close
