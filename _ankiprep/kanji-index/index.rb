require 'misc/urlify'
require 'misc/template'
require 'misc/utf16'
require 'misc/progress'
require_relative '../kanji/stats'
require_relative '../kanji-wordlist/format'


module Index

  def Index.makereport

    print "[Index] generating index.html... "

    Dir.mkdir $OUTDIR unless File.exist? $OUTDIR

    Progress.new do |pr|

      body = "#{Stats.all_kanji.size} kanji<br>\n"
      Stats.all_kanji.each do |k|
        body << "<span id=\"k#{k.utf16_code}\">#{k}</span>".urlify("kanji-flashcards/k#{k.utf16_code}.html", 'flashcard')
      end

      File.open($OUTDIR+'/kanji-index.html','w') do |f|
        f.write $T['kanji-index/index.html'].with(
          :CSS => File.read('kanji/gray.css'),
          :BODY => body,
          :FRAMEIDS => Stats.all_kanji.map {|k| "'#{k.utf16_code}'"}.join(',')
        )
      end

    end #progress

  end

end
