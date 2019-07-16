# encoding: UTF-8
#$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'FileUtils'
require 'sqlite3'

$ANKIDIR = 'D:/German/_anki'
$OUTDIR = '__OUT__'


$infile = ARGV[0]

if $infile
  lines = File.read($infile, :encoding => 'UTF-8').
    sub("\xEF\xBB\xBF",'').
    split("\n").
    map {|line| line.chomp}

  $new_entries = lines.map {|line|
    if m = line.match(/(.+),\s+(der|die|das)\s+(.+)$/)
      [m[1], m[2], m[3]]
    elsif m = line.match(/(.+)\s+\(.+\)/)
      [m[1], nil, nil]
    else
      [line, nil, nil]
    end
  }.compact
else
  puts "no input file; will just regenerate #{$OUTDIR}/vocab_DE.html"
  $new_entries = []
end


ankihash = Hash.new {|h,factId| h[factId] = []}
db = SQLite3::Database.new("#{$ANKIDIR}/vocab_DE.anki")
db.execute('select factId,ordinal,value from fields') do |row|
  factId, ordinal, value = row[0], row[1], row[2]
  ankihash[factId][ordinal] = value
end
$anki_entries = ankihash.map do |factId,entry|
  entry
end


$all_entries = $anki_entries
$new_entries.each do |ne|
  $all_entries << ne unless $all_entries.any? {|ae| ae[0] == ne[0]}
end
$all_entries.sort_by! {|ae| ae[0]}


FileUtils.mkdir_p $OUTDIR

File.open("#{$OUTDIR}/vocab_DE.html",'w') do |f|
f.puts <<-HTML
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<style type="text/css">
table {
  border-collapse: collapse;
}
td {
  font-size: 18pt;
  min-width: 100px;
  border: 1px solid black;
  padding: 7px;
  align: middle;
}
tr:nth-child(even) {background-color: #f2f2f2;}
</style>
</head>
<body>
HTML
  f.puts "<table>"
  $all_entries.each do |e|
    expr = e[0]
    noun_article = e[1]
    noun_plural = e[2]
    verb_conj = e[3]
    meaning = e[4]
    urls =
      "<a href=\"https://en.langenscheidt.com/german-english/#{expr}\" target='_blank'>" +
        "<img src='http://127.0.0.1/vocab_DE/ico/favicon_langenscheidt.ico' height=25px></a>&nbsp" +
      "<a href=\"https://www.linguee.com/english-german/search?source=auto&query=#{expr}\" target='_blank'>" +
        "<img src='http://127.0.0.1/vocab_DE/ico/favicon_linguee.ico' height=25px></a>&nbsp" +
      "<a href=\"https://www.collinsdictionary.com/dictionary/german-english/#{expr}\" target='_blank'>" +
        "<img src='http://127.0.0.1/vocab_DE/ico/favicon_collinsdictionary.ico' height=25px></a>&nbsp" +
      "<a href=\"https://www.verbformen.com/conjugation/?w=#{expr}\" target='_blank'>" +
        "<img src='http://127.0.0.1/vocab_DE/ico/favicon_verbformen.ico' height=25px></a>&nbsp"
#    f.puts "<tr id=#{expr}><td>#{urls}</td><td>#{expr}</td><td>#{noun_article}</td><td>#{noun_plural}</td><td>#{verb_conj}</td><td>#{meaning}</td></tr>"
    f.puts "<tr id=#{expr}><td>#{expr}</td><td>#{urls}</td></tr>"
  end
  f.puts "</table>"
  f.puts "<br>"*50
  f.puts "---"
end


if !$new_entries.empty?
  File.open("D:/vocab_DE[IMPORT].txt",'w') do |f|
    $new_entries.shuffle.each do |entry|
      article = entry[1]
      expr = entry[0]
      conj_plural = entry[2]
      links = "<a href=\"http://127.0.0.1/vocab_DE##{expr}\"><span style=\"text-decoration: underline; color:#0000ff;\">...</span></a>"
      audio = ''
      meaning = ''
      f.puts "#{article}\t#{expr}\t#{conj_plural}\t#{links}\t#{audio}\t#{meaning}"
    end
  end
end
