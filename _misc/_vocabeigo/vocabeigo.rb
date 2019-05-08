# encoding: UTF-8
$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'edict'
require 'misc/utf8'

f = File.open('vocab-with-eigo.txt','w')

Utf8.readlines('vocab-exp.txt').each do |line|
  if m = line.match(/(.*)\t(.+)\t(.+)\t(.+)/m)
    expr = m[2].split(Utf8::Space)[0]
    kana = m[3].split(Utf8::Space)[0]
    entries = Edict.lookup_expr(expr).delete_if {|e| e.kana != kana}
    raise "WTF: #{line}" if entries.any? {|e| e.expr != expr}
    eigo = entries.map {|e| e.eigoc}.join('; ')
    f.puts "#{m[1]}\t#{m[2]}\t#{m[3]}\t#{m[4]}\t#{eigo}"
  else
    puts "ACHTUNG: #{line}"
  end
end
