# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'json'
require 'misc/utf16'
require_relative '../_ankiprep/anki/anki.rb'


$anki_kanji = Anki.read("#{$ANKIDIR}/kanji.anki").map do |kanji,json|
  json_q = json.gsub('use:',    '"use":'   ).
                gsub('freq:',   '"freq":'  ).
                gsub('words:',  '"words":' ).
                gsub('other:',  '"other":' ).
                gsub('yomi:',   '"yomi":'  ).
                gsub('nanori:', '"nanori":').
                gsub('eigo:',   '"eigo":'  ).
                gsub('utf16:',  '"utf16":' ).
                gsub('kanji:',  '"kanji":' ).
                gsub('kjt:',    '"kjt":'   )
  if kanji != JSON.parse(json_q)['kanji']
    errors_kanji << "mismatch: [#{kanji.inspect}] | " + JSON.parse(json_q)['kanji']
  end
  kanji.chomp
end


$gif_kanji = Dir["#{$DICT_DIR}/gif/kanji/u????.gif"].map do |file|
  file.split('/').last.split('.').first[1..4].charfrom_utf16
end


$missing_kanji = $anki_kanji - $gif_kanji

puts "#{$anki_kanji.size} kanji in Anki"
puts "Have #{$gif_kanji.size} gifs, need #{$missing_kanji.size}"


File.open('kanji.txt','w:UTF-8') {|f| f.write $missing_kanji.join}
