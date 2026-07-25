# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'kanjidic'
require 'misc/utf16'


$gif_kanji = Dir["#{$DICT_DIR}/gif/kanji/u????.gif"].map do |file|
  file.split('/').last.split('.').first[1..4].charfrom_utf16
end

$kanjidic_kanji = []
Kanjidic.each_kanji {|k| $kanjidic_kanji << k}

$missing_kanji = $kanjidic_kanji - $gif_kanji

puts "#{Kanjidic.size} kanji in Kanjidic"
puts "Have #{$gif_kanji.size} gifs, need #{$missing_kanji.size}"

File.open('kanji_all.txt','w:UTF-8') {|f| f.write $missing_kanji.join}
