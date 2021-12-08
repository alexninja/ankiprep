module Vocab; module Report

  def self.make_htmls(rikai_words)
    groups = [
      [
        'group-all.html',
        'All',
        rikai_words
      ],
      [
        'group-exact-expr.html',
        '├─!exact expr',
        rikai_words.select {|w| w.flags_all? :exact_expr}
      ],
      [
        'group-exact-kana.html',
        '└─exact !kana',
        rikai_words.select {|w| w.flags_all? :exact_kana}
      ],
      [
        'group-good.html',
        'Good',
        rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                    select {|w| !w.error}
      ],
      [
        'group-good-no-audio.html',
        '├─no audio',
        rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                    select {|w| !w.error}.
                    select {|w| !Audio.have?(w)}
      ],
      [
        'group-alt-expr.html',
        '├─alt expr preferred',
        rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                    select {|w| !w.error}.
                    select {|w| w.flags_all? :alt_expr}
      ],
      [
        'group-alt-kana.html',
        '├─alt kana preferred',
        rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                    select {|w| !w.error}.
                    select {|w| w.flags_all? :alt_kana}
      ],
      [
        'group-skip-edict.html',
        '└─*skip Edict',
        rikai_words.select {|w| w.flags_all? :skip_edict}
      ],
      [
        'group-dupes.html',
        'Duplicates',
        rikai_words.select {|w| w.flags_any? :dupe_in_anki, :dupe_in_rikai}
      ],
      [
        'group-dupes-anki.html',
        '└─in Anki',
        rikai_words.select {|w| w.flags_all? :dupe_in_anki}
      ],
      [
        'group-dupes-anki-alts.html',
        '&nbsp;&nbsp;└─in alts',
        rikai_words.select {|w| w.flags_all? :dupe_in_anki, :dupe_in_alts}
      ],
      [
        'group-dupes-rikai.html',
        '└─in input',
        rikai_words.select {|w| w.flags_all? :dupe_in_rikai}
      ],
      [
        'group-dupes-rikai-alts.html',
        '&nbsp;&nbsp;└─in alts',
        rikai_words.select {|w| w.flags_all? :dupe_in_rikai, :dupe_in_alts}
      ],
      [
        'group-errors.html',
        'Errors',
        rikai_words.select {|w| w.error}
      ],
      [
        'group-not-in-edict.html',
        '└─not in Edict',
        rikai_words.select {|w| w.flags_all? :not_in_edict}
      ]
    ]

    print "[Vocab::Report] generating HTML reports... "

    Progress.new(groups.size) do |pr|
      groups.each_with_index do |gr,i|
        make_html gr[0], gr[1], gr[2], i
        pr.tick
      end
    end

    File.open($OUTDIR+'/vocab/index.html','w:UTF-8') do |f|
      headers = []
      groups.each_with_index do |gr,i|
        text = "#{gr[1]} (#{gr[2].size})"
        headers << if gr[2].empty?
          $T['vocab/report/header-d.html'].with(
            TEXT: text
          )
        else
          $T['vocab/report/header.html'].with(
            URL: 'report/' + gr[0],
            GROUPID: i,
            TEXT: text
          )
        end
      end
      f.write $T['vocab/report/index.html'].with(
        HEADERS: headers.join("\n"),
        GROUPCOUNT: groups.size
      )
    end
    
    File.open($OUTDIR+'/vocab/report/report.css','w:UTF-8') do |f|
      f.write $T['vocab/flashcard/flashcard.css'].apply_ifdef('REPORT')
    end

    File.open('report-vocab.html','w') do |f|
      f.write $T['vocab/report/report.html'].with(OUTDIR: $OUTDIR)
    end
  end


private

  def self.make_html(filename, title, group, groupid)
    entries = group.map do |w|
      if w.flags_all? :dupe_in_anki
        entries = w.xref.entries
        error = "Duplicate in Anki (reproduced here)"
        bgcol = '#FFFFCC'
      elsif w.flags_all? :dupe_in_rikai
        entries = w.xref.entries
        error = "Duplicate of line <a href=group-all.html##{w.xref.lineno}>#{w.xref.lineno}</a> (reproduced here)"
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
        $T['vocab/report/kanaeigo.html'].with(
          KANA: e.kana.gray_if(!e.priority?) + Audio.html_marker(expr, e.kana),
          ALTS: alts.join(Utf8::Space),
          EIGO: e.eigoc
        )
      end.join("\n")
      $T['vocab/report/entry.html'].with(
        ANCHOR: w.lineno,
        LINE: "<b>#{w.lineno}.</b>&nbsp;" + w.line.highlight(w.expr),
        BGCOL: bgcol,
        EXPR: expr.highlight(w.expr, expr==w.expr),
        KANAEIGO: kanaeigo,
        ERROR: error ? $T['vocab/report/error.html'].with(ERROR: error) : ''
      )
    end.join("\n")

    FileUtils.mkdir_p $OUTDIR+'/vocab/report'

    heading = title.gsub('&nbsp;','').chars.to_a.select {|c| c.ascii_only?}.join + " (#{group.size})"

    File.open($OUTDIR+'/vocab/report/'+filename,'w:UTF-8') do |f|
      f.write $T['vocab/report/group.html'].with(
        GROUPID: groupid,
        HEADING: heading,
        ENTRIES: entries
      )
    end
  end

end; end
