# moved here. probably won't work from this dir.

# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'edict'
require 'kanjidic'
require_relative 'yomi/parse'

Edict.each do |e|
  next unless e.expr.chars.size == 3 && e.expr[0].kanji? && e.expr[1].kanji? && e.expr[2].hir? && e.eigo.include?('(v')
  if Edict.lookup_expr(e.expr[1..-1]).any? {|z| e.kana.chars.last(z.kana.chars.size).join == z.kana}
    next
  end
  puts "#{e.expr} #{e.kana} #{e.eigoc}" if e.seki.empty?
end


#:yomi, :frag, :moji)
##{e.seki[0].yomi} #{e.seki[1].yomi} 