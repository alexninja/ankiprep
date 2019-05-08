# encoding: UTF-8
$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'edict'
require 'kanjidic'

File.open('yojijukugo.txt','w') do |f|
  yoji = []
  Edict.each do |e|
    if e.expr.size == 4 && e.expr.chars.all? {|c| c.kanji?}
      count = e.expr.chars.inject(0) {|sum,k| sum += Kanjidic.stroke_count(k)}
      yoji << [e,count]
    end
  end
  yoji.sort_by {|e,count| count}.reverse[0..49].each do |e,count|
    f.puts "(#{count}) #{e.expr} (#{e.kana}) #{e.eigoc}"
  end  
end