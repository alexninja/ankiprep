module Kanji; module Report

  def self.make_htmls
    print "[Kanji::Report] generating HTML reports... "

    File.open('report-kanji.html','w') do |f|
      f.write $T['kanji/report/report.html'].with(OUTDIR: $OUTDIR)
    end

    Progress.new do |pr|
      body = "#{Kanji::Stats.all_kanji.size} kanji<br>\n"
      Kanji::Stats.all_kanji.each do |k|
        body << "<span id=\"k#{k.utf16_code}\">#{k}</span>".urlify("flashcard/k#{k.utf16_code}.html", 'flashcard')
      end
      File.open($OUTDIR+'/kanji/index.html','w') do |f|
        f.write $T['kanji/report/index.html'].with(
          :CSS => File.read('kanji/report/gray.css'),
          :BODY => body,
          :FRAMEIDS => Kanji::Stats.all_kanji.map {|k| "'#{k.utf16_code}'"}.join(',')
        )
      end
    end #progress

  end

end; end
