$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

$KCODE = 'U'

Tango  = Struct.new(:expr, :kana)
Seki   = Struct.new(:yomi, :frag, :moji)
Parsed = Struct.new(:tango, :arr)

require 'kanjidic'
require 'kana'
require 'misc/moji'
require 'misc/progress'
require 'misc/utf8'
require 'onyomi/format'
require 'onyomi/read_pairs'
require 'onyomi/recparse'
require 'set'


words = read_pairs('allwords.txt').
  map {|p| Tango.new(p[0], p[1])}.
  delete_if {|t| t.expr.moji.size == 1}

# parse

report = ''
anki = ''
parsed = []

progress = Progress.new(words.size)
words.each_with_index do |w,i|
  size = report.size

  recparse(w.expr.moji, w.kana.moji, []) do |arr|
    report << format_table(w, arr) << "\n"
    parsed << Parsed.new(w, arr)
    break
  end

  if report.size == size
    report << format_table(w, []) << "\n"
  end

  progress.tick(i)
end

# group

khash = Hash.new {|h,kanji| h[kanji] = Hash.new {|h,onyomi| h[onyomi] = []}}

parsed.each do |p|
  raise "yomi doesn't match!" unless p.tango.kana == p.arr.map {|x| x.frag}.join
  raise "expr doesn't match!" unless p.tango.expr == p.arr.map {|x| x.moji}.join

  p.arr.each do |x|
    next unless x.moji.kanji?

    kanji = x.moji

    if x.yomi.kat?
      hl = p.arr.map {|xx| xx.yomi == x.yomi and xx.moji == x.moji}
      kana = p.arr.zip(hl).map {|z| if z[1]; '<b>'+z[0].frag+'</b>'; else; z[0].frag; end}.join
      expr = p.tango.expr
      onyomi = x.yomi
      tango = Tango.new(expr, kana)
      khash[kanji][onyomi] << tango unless khash[kanji][onyomi].include? tango
    else
      kunyomi = x.yomi
      khash[kanji][kunyomi]
    end
  end
end  # each khash[kanji] is a hash with keys for every yomi (on and kun) encountered while parsing

khash.freeze

report << "<br><hr size=1>ONYOMI DUMP<br>\n"

# add to report and to anki import file: [ key(kanji+onyomi) onyomi kanji kana expr eigo shosai ]

khash.each_key do |kanji|
  eigo = Kanji.eigo(kanji).join(', ')
  report << "<a name=\"#{Utf16.str(kanji)}\"><br>#{kanji} (#{eigo})<br></a>\n"
  khash[kanji].each_key do |yomi|
    report << "#{Utf8::BracketOpen}#{Utf8::Space}#{yomi}#{Utf8::Space}#{Utf8::BracketClose}#{Utf8::Space}"
    if yomi.kat?
      tangoarr = khash[kanji][yomi].sort_by {|t| t.kana.index('<b>')}
      kana = tangoarr.map {|t| t.kana}.join(Utf8::Space)
      expr = tangoarr.map {|t| t.expr}.join(Utf8::Space)
      shosai = format_shosai(expr)
      report << "#{Utf8::Rarrow}#{Utf8::Space}#{kana}#{Utf8::Space}#{Utf8::Rarrow}#{Utf8::Space}#{expr}" <<
                "#{Utf8::Space}#{Utf8::Rarrow}#{Utf8::Space}#{shosai}<br>\n"
      anki << "#{kanji}+#{yomi}\t#{yomi}\t#{kanji}\t#{kana}\t#{expr}\t#{eigo}\t#{shosai}\n"
    else
      report << "<br>\n"
    end
  end
end

report << "<br><hr size=1><br>\n"

# statistics

kwithon = Set.new
kkunonly = Set.new

khash.each_key do |kanji|
  if khash[kanji].to_a.any? {|x| x[0].kat?}
    kwithon << kanji
  else
    kkunonly << kanji
  end
end

report << "total kanji: #{khash.size}<br>\n#{khash.to_a.map {|x| x[0]}.sort.join(Utf8::Space)}<br><br>\n"

kwithon_href = kwithon.to_a.sort.map {|k| "<a href=\"##{Utf16.str(k)}\">#{k}</a>"}.join(Utf8::Space)
report << "kanji with ON yomi (writing practice): #{kwithon.size}<br>\n#{kwithon_href}<br><br>\n"

report << "kanji with KUN yomi only (no writing practice): #{kkunonly.size}<br>\n#{kkunonly.to_a.sort.join(Utf8::Space)}<br><br>\n"

# dump anki

report << "<hr size=1><br>\n"

File.open('anki.onyomi.txt','w') {|f| f.write anki}
ankisize = anki.split("\n").size
report << "created anki.onyomi.txt, #{ankisize} lines<br>\n[ key onyomi kanji kana expr eigo shosai ] <br><br>\n"

# dump report

File.open('report.html','w') {|f| f.write format_html(report)}

