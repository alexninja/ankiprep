$KCODE = "U"

require '../libs/kanji/kanji'
require '../libs/utf16'

Kanji.load('D:\Japanese\edict\kanjidic.utf8')

Kanji.each_kanji {|k| print k}
