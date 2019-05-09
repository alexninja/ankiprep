require 'misc/template'
require_relative 'stats'
require_relative '../kanji-wordlist/format'
require_relative '../kanji-flashcard/format'
require_relative '../kanji-index/index'

$REPORTDIR = '__OUT__'


module Kanji

  def Kanji.makeall
    Stats.init
    Wordlist.makeall
    Flashcard.makeall
    Kanji.makereport
    Index.makereport
  end


private

  def Kanji.makereport
    Dir.mkdir $REPORTDIR unless File.exist? $REPORTDIR
    File.open('report-kanji.html','w') do |f|
      f.write $T['kanji/report.html'].with(REPORTDIR: $REPORTDIR)
    end
  end

end
