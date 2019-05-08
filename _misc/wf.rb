# encoding: UTF-8
$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'edict'
require 'kana'
require 'kanjidic'
require 'misc/utf8'

f = File.open('wf.txt','w')

wordcount = 0

Utf8.readlines('base_aggregates.txt').reverse.each do |line|
  m = line.match(/(\d+)\t(.*)\t.+/)
  next unless m

  expr = m[2]
  if !expr.empty? && expr.chars.all? {|_| _.kanji? || _.kana?}
    entries = (Edict.lookup_expr(expr) + Edict.lookup_kana(expr)).uniq.delete_if {|e| !e.priority?}
    next if entries.empty?
    wordcount += 1
    f.puts "#{wordcount}: #{expr}"
    entries.uniq.each do |entry|
      f.puts "#{entry.expr} [#{entry.kana}] #{entry.eigoc}"
    end
    f.puts
  end
  
  break if wordcount >= 100
end
