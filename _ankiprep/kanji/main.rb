require 'misc/template'
require 'misc/urlify'
require_relative 'stats'
require_relative 'wordlist/format'
require_relative 'flashcard/format'


module Kanji

  def Kanji.makeall
    Stats.init
    Wordlist.makeall
    Flashcard.makeall
    Kanji.makereport
  end


private

  def Kanji.makereport
    print "[Kanji] generating report.html... "
    File.open('report-kanji.html','w') do |f|
      f.write $T['kanji/report.html'].with(OUTDIR: $OUTDIR)
    end

    print "[Kanji] generating index.html... "
    Progress.new do |pr|
      body = "#{Kanji::Stats.all_kanji.size} kanji<br>\n"
      Kanji::Stats.all_kanji.each do |k|
        body << "<span id=\"k#{k.utf16_code}\">#{k}</span>".urlify("flashcard/k#{k.utf16_code}.html", 'flashcard')
      end
      File.open($OUTDIR+'/kanji/index.html','w') do |f|
        f.write $T['kanji/index.html'].with(
          :CSS => File.read('kanji/gray.css'),
          :BODY => body,
          :FRAMEIDS => Kanji::Stats.all_kanji.map {|k| "'#{k.utf16_code}'"}.join(',')
        )
      end
    end #progress

  end

end
