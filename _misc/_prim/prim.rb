# encoding: UTF-8
$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'misc/template'

t = T.new('.')

COLUMN_SIZE = 18
primitives = 0
columns = []
trs = []

File.readlines("strokes.html", mode:"r:Shift_JIS:UTF-8").each do |line|
  if m = line.match(/<P><FONT SIZE=\"\+3\"><A HREF=\".+.html\"><FONT COLOR=\"RED\">(.+)<\/FONT\><\/A><\/FONT> (.+?) (.+)<\/P>/)
    prim, kana, eigo = m[1], m[2], m[3]
    eigo.sub!('no SJIS glyph','')
    trs << t['tr.html'].with(PRIM: prim, KANA: "<nobr>"+kana+"</nobr>", EIGO: eigo)
    primitives += 1
  end
  if trs.size == COLUMN_SIZE
    columns << t['column.html'].with(TRS: trs.join)
    trs = []
  end
  if m = line.match(/<FONT SIZE = \"\+2\">(.+)<\/FONT>/)
    count = m[1]
    trs << t['tr-count.html'].with(COUNT: count)
  end
end

if trs.size > 0
  columns << t['column.html'].with(TRS: trs.join)
end

File.open("_report.html",'w') do |f|
  f.write t['prim.html'].with(COLUMNS: columns.join)
end

puts "found #{primitives} primitives"
