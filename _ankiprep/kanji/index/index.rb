require 'fileutils'
require 'misc/urlify'
require 'misc/template'
require 'misc/utf16'
require 'misc/progress'
require_relative '../stats'
require_relative '../wordlist/format'


module Index

  def Index.makereport

    print "[Index] generating index.html... "

    FileUtils.mkdir_p $OUTDIR

    Progress.new do |pr|

      body = "#{Stats.all_kanji.size} kanji<br>\n"
      Stats.all_kanji.each do |k|
        body << "<span id=\"k#{k.utf16_code}\">#{k}</span>".urlify("flashcards/k#{k.utf16_code}.html", 'flashcard')
      end

      File.open($OUTDIR+'/kanji/index.html','w') do |f|
        f.write $T['kanji/index/index.html'].with(
          :CSS => File.read('kanji/gray.css'),
          :BODY => body,
          :FRAMEIDS => Stats.all_kanji.map {|k| "'#{k.utf16_code}'"}.join(',')
        )
      end

    end #progress

  end

end
