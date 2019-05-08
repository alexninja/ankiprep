$KCODE = "U"

require '../libs/kanji/kanji'
require '../libs/kanji/make_html'
require '../libs/bighash'
require '../libs/chomp_utf8'

Kanji.load('D:\Japanese\dict\edict\kanjidic.utf8')

$INFILE = 'ramen.txt'
$GIFDIR = 'D:/Japanese/dict/gif'

puts "reading #{$INFILE}"

words = File.readlines($INFILE)

words.each_with_index do |line,i|

  line.chomp_utf8!
  line.sub!('<br><br>',"\t")

  File.open('tmp.html','w') {|f| f.write Kanji.make_html(line)}

end
