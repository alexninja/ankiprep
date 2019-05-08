
module Vocab

private
  @t = T.new('vocab-wordlist')


  def Vocab.make_wordlist(filename, title, wordlist, pageid)
    words = wordlist.map do |w|
      if w.flags_all? :dupe_in_anki
        entries = w.xref.entries
        error = "Duplicate in Anki (reproduced here)"
        bgcol = '#FFFFCC'
      elsif w.flags_all? :dupe_in_rikai
        entries = w.xref.entries
        error = "Duplicate of line <a href=wordlist-all.html##{w.xref.lineno}>#{w.xref.lineno}</a> (reproduced here)"
        bgcol = '#EEEEEE'
      else
        entries = w.entries
        error = w.error
        bgcol = 'white'
      end
      if w.flags_all? :skip_edict
        error = "Skipped Edict (created raw)"
      end
      expr = (entries.empty?) ? w.expr : entries.first.expr
      kanaeigo = entries.map do |e|
        alts =
          e.alts[0].map do |a|  # kana alts
            a.gsub('~','').
              gray_if(a[0]=='~') +
              Audio.html_marker(expr, a.gsub('~',''))
          end +
          e.alts[1].map do |a|  # expr alts
            a.gsub('~','').
              gray_if(a[0]=='~').
              highlight(w.expr, a.gsub('~','')==w.expr) +
              Audio.html_marker(a.gsub('~',''), e.kana)
          end
        @t['kanaeigo.html'].with(
          KANA: e.kana.gray_if(!e.priority?) + Audio.html_marker(expr, e.kana),
          ALTS: alts.join(Utf8::Space),
          EIGO: e.eigoc
        )
      end.join("\n")
      @t['word.html'].with(
        ANCHOR: w.lineno,
        LINE: "<b>#{w.lineno}.</b>&nbsp;" + w.line.highlight(w.expr),
        BGCOL: bgcol,
        EXPR: expr.highlight(w.expr, expr==w.expr),
        KANAEIGO: kanaeigo,
        ERROR: error ? @t['error.html'].with(ERROR: error) : ''
      )
    end.join("\n")

    Dir.mkdir($REPORTDIR) unless File.exist?($REPORTDIR)
    Dir.mkdir($REPORTDIR+'/vocab-wordlists') unless File.exist?($REPORTDIR+'/vocab-wordlists')

    heading = title.gsub('&nbsp;','').chars.to_a.select {|c| c.ascii_only?}.join + " (#{wordlist.size})"

    File.open($REPORTDIR+'/vocab-wordlists/'+filename,'w:UTF-8') do |f|
      f.write @t['wordlist.html'].with(
        PAGEID: pageid,
        HEADING: heading,
        WORDS: words
      )
    end
  end

end # module
