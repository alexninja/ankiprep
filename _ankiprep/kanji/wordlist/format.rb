require 'kanjidic'
require 'misc/template'
require 'misc/progress'
require 'misc/utf16'
require 'misc/gray'


module Kanji; module Wordlist

  def self.makeall
    print "[Kanji::Wordlist] generating #{Kanji::Stats.relevant_kanji.size} html files... "

    FileUtils.mkdir_p $OUTDIR+'/kanji/wordlist'

    Progress.new(Kanji::Stats.relevant_kanji.size) do |pr|
      Kanji::Stats.relevant_kanji.each do |k|
        make_html(k)
        pr.tick
      end
    end

    FileUtils.cp 'kanji/wordlist/wordlist.css', $OUTDIR+'/kanji/wordlist'
  end


private

  def self.make_html(k)
    body = ''
    @eigo_id = 0
    yarr = Kanji::Stats.yarr(k) + [:other]

    filename = $OUTDIR + '/kanji/wordlist/w' + k.utf16_code + '.html'

    yarr.each do |yomi|
      [ANK,POM,MON,EDI].each do |src|
        body << format_wordlist(src, k, yomi)
      end
    end

    File.open(filename, 'w') do |f|
      f.write $T['kanji/wordlist/page.html'].with(BODY: body)
    end
  end


  def self.format_wordlist(src, k, yomi)
    wi_list = Kanji::Stats.words(src, k, yomi)
    return '' if wi_list.empty?

    word_trs = wi_list.map do |wi|
      $T['kanji/wordlist/word-tr.html'].with(
        COUNT: wi.n,
        EXPR: "<nobr>" + wi.expr.html_gray_if(wi.entries.all? {|e| !e.priority?}) + "</nobr>",
        DETAILS: wi.entries.map do |e|
                    @eigo_id += 1
                    kana_brk = bracket_kana(e,k)
                    if e.alts.flatten.empty?
                      alts_js, alts = '', ''
                    else
                      alts_js = ',"' + e.alts[0].join(' ') + (e.alts[0].empty? || e.alts[1].empty? ? '' : ';') + e.alts[1].join(' ') + '"'
                      alts = '&nbsp;'*4 + e.alts.flatten.map { |a| (a[0]=='~' ? a[1..-1].gray : a) }.join(Utf8::Space)
                    end
                    $T['kanji/wordlist/details.html'].with(
                      YOMI_JS: Flashcard.bracket_yomi(yomi),
                      KANA_JS: kana_brk,
                      EXPR_JS: wi.expr,
                      EIGO_ID_JS: @eigo_id,
                      PRIORITY_JS: e.priority?,
                      ALTS_JS: alts_js,
                      KANA: bracket_to_span(kana_brk),
                      EIGO: e.eigoc.gray_if(!e.priority?),
                      ALTS: alts,
                      NOTE: (e.fake?) ? '&nbsp;&nbsp;&nbsp;&nbsp;Not in Edict' : ''
                    )
                  end.join('<br>')
      )
    end.join

    title =
      Utf8::BracketOpen +
      bracket_to_span(Flashcard.bracket_yomi(yomi.to_s)) +
      Utf8::BracketClose +
      ' ' +
      ["Anki","Pomax","Monash","Edict"][src]

    $T['kanji/wordlist/wordlist.html'].with(
      ANCHOR: %w[ank pom mon edi][src] + '_' + Flashcard.bracket_yomi(yomi),
      TITLE: "#{title} (#{wi_list.size} words)",
      WORD_TRS: word_trs)
  end


  def self.bracket_kana(e,k)
    # generates a special kana string for consumption in html
    # example output: "machi(a)waseru", "[ei]ga"
    return e.kana if e.seki.empty?
    e.seki.map do |s|
      if s.moji == k
        if s.yomi.kat?
          '[' + s.frag + ']'
        else
          '(' + s.frag + ')'
        end
      else
        s.frag
      end
    end.
      join
  end

  def self.bracket_to_span(str)
    str.gsub('[', "<span class='on'>").
        gsub('(', "<span class='kun'>").
        gsub(']', "</span>").
        gsub(')', "</span>")
  end

end; end
