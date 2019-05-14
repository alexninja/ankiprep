require 'fileutils'
require 'misc/template'
require_relative 'stats'
require_relative 'wordlist/format'
require_relative 'flashcard/format'
require_relative 'index/index'


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
    FileUtils.mkdir_p $OUTDIR
    File.open('report-kanji.html','w') do |f|
      f.write $T['kanji/report.html'].with(OUTDIR: $OUTDIR)
    end
  end

end
