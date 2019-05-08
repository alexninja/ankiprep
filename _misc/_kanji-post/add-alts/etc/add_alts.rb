
def add_alts(line)

  fragments = []
  entries, entries2 = [], []

  line.scan(/\[\"(.+?)\",\"(.+?)\",\"(.+?)\",(true|false)(|,\".+?\")\]/).each do |kana,expr,_eigo,_priority,_alts|
    fragments << "[\"#{kana}\",\"#{expr}\",\"#{_eigo}\",#{_priority}#{_alts}]"

    eigo = _eigo.unescape
    priority = (_priority=="true") ? true : false
    alts = (_alts.empty?) ? "" : _alts[2..-2]

    entries << [kana,expr,eigo,priority,alts]
  end

  entries.each do |kana,expr,eigo,priority,alts|
    kana_cln = kana.gsub('[','').gsub(']','').gsub('(','').gsub(')','')
    ek = Edict.lookup_expr(expr).select {|e| e.kana == kana_cln}

    kana2,expr2,eigo2,priority2,alts2 = kana,expr,eigo,priority,alts

    if ek.size == 0
      # keep as is
    elsif ek.size == 1
      eigo2 = ek[0].eigoc
      priority2 = ek[0].priority?
      alts2 = ek[0].alts
    else
      eke = ek.select {|e| e.eigoc == eigo}
      if eke.size == 1
        priority2 = eke[0].priority?
        alts2 = eke[0].alts
      else
        # keep as is, but log it - if anything shows up in the log, I'll need to change this code
        $log.puts "[Warning] More than 1 Edict entry and no eigo matches for #{expr} #{kana} \"#{eigo}\" (#{priority})"
        ek.each {|e| $log.puts "- #{e.expr} #{e.kana} \"#{e.eigoc}\""}
        $log.puts
        $warnings += 1
      end
    end

    if alts2.class == Array
      # change alts2 from array of arrays to string; lose elements containing weird characters
      alts_v = alts2.map {|ar| ar.delete_if {|a| (a[0]=='~'?a[1..-1]:a).chars.any? {|c| !c.kanji? && !c.kana?}}}
      alts2 = alts_v[0].join(' ') + (alts_v[0].empty? || alts_v[1].empty? ? '' : ';') + alts_v[1].join(' ')
    end

    entries2 << [kana2,expr2,eigo2,priority2,alts2]
  end

  entries_html = ""
  line_html = line.dup
  line2_html = line.dup
  line2 = line.dup

  entries.each_index do |i|
    kana,expr,eigo,priority,alts = entries[i]
    kana2,expr2,eigo2,priority2,alts2 = entries2[i]

    entries_html << $t['entry.html'].with(
      KANA:             kana,
      EXPR:             expr,
      EIGO_HEADING:     (eigo == eigo2) ? "eigo" : "eigo!",
      PRIORITY_HEADING: (priority == priority2) ? "pr" : "pr!",
      PRIORITY:         (priority == priority2) ? priority : "<span class='changed'>#{priority2}</span>",
      ALTS_HEADING:     (alts == alts2) ? "alts" : "alts!",
      ALTS:             (alts == alts2) ? alts : "#{alts}<br><span class='changed'>#{alts2}</span>"
    ).
      safe_sub('$EIGO', (eigo == eigo2) ? eigo : "#{eigo}<br><span class='changed'>#{eigo2}</span>")

    _alts2 = (alts2.empty?) ? "" : ",\"#{alts2}\""
    fragment2 = "[\"#{kana2}\",\"#{expr2}\",\"#{eigo2.escape}\",#{priority2}#{_alts2}]"

    line_html  = line_html.safe_sub(  fragments[i], "<span class='fragment'>#{fragments[i]}</span>")
    line2_html = line2_html.safe_sub( fragments[i], "<span class='fragment'>#{fragment2}</span>")
    line2      = line2.safe_sub(      fragments[i], fragment2)
  end

  line2_html = line2_html.gsub('use:1','use:true').gsub('use:0','use:false').gsub('", "','","')
  line2      = line2.     gsub('use:1','use:true').gsub('use:0','use:false').gsub('", "','","')

  html = $t['card.html'].
    safe_sub('$LINE_HTML',    line_html).
    safe_sub('$ENTRIES_HTML', entries_html).
    safe_sub('$LINE2_HTML',   line2_html)

  [line2, html]

end
