require 'set'
require 'fileutils'
require 'json'
require 'edict'
require 'kanjidic'
require 'misc/utf8'
require 'misc/gray'
require 'misc/template'
require 'misc/progress'
require_relative '../anki/anki'
require_relative 'word'
require_relative 'string'
require_relative 'audio'
require_relative '../vocab-wordlist/format'



module Vocab

  def Vocab.makeall
    anki_words, rikai_words = parse_input

    make_wordlists(rikai_words)
    make_anki(rikai_words)

    @vocab_list = make_vocab_list(anki_words, rikai_words)
  end

  def Vocab.input_file_present?
    @input_file_present
  end

  def Vocab.vocab_list
    @vocab_list
  end


private

  def Vocab.parse_input
    print "[Vocab] reading #{$ANKIDIR}/vocab.anki... "
    anki_words = Anki.read("#{$ANKIDIR}/vocab.anki").map do |expr,json|
      Word.from_anki(expr,json)
    end
    puts "#{anki_words.size} vocab entries"

    print "[Vocab] reading D:/_rikaichan.txt... "
    rikai_words = []
    if File.exists?("D:/_rikaichan.txt")
      @input_file_present = true
      rikai_words = Utf8::readlines("D:/_rikaichan.txt").map.with_index do |line,i|
        Word.from_line(line, i+1)
      end
      puts
    else
      @input_file_present = false
      puts "Not Found. Will Regenerate Everything in __OUT__!"
    end
    #p (anki.values + rikai.values).map {|ar| ar.size}.to_set

    [ anki_words.freeze, rikai_words.freeze ]
  end


  def Vocab.make_wordlists(rikai_words)
    wordlists = [
      [
        'wordlist-all.html',
        'All',
        rikai_words
      ],
      [
        'wordlist-exact-expr.html',
        '├─exact !expr',
        rikai_words.select {|w| w.flags_all? :exact_expr}
      ],
      [
        'wordlist-exact-kana.html',
        '└─exact !kana',
        rikai_words.select {|w| w.flags_all? :exact_kana}
      ],
      [
        'wordlist-good.html',
        'Good',
        rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                    select {|w| !w.error}
      ],
      [
        'wordlist-good-no-audio.html',
        '├─no audio',
        rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                    select {|w| !w.error}.
                    select {|w| !Audio.have?(w)}
      ],
      [
        'wordlist-alt-expr.html',
        '├─alt expr preferred',
        rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                    select {|w| !w.error}.
                    select {|w| w.flags_all? :alt_expr}
      ],
      [
        'wordlist-alt-kana.html',
        '├─alt kana preferred',
        rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                    select {|w| !w.error}.
                    select {|w| w.flags_all? :alt_kana}
      ],
      [
        'wordlist-skip-edict.html',
        '└─skip Edict',
        rikai_words.select {|w| w.flags_all? :skip_edict}
      ],
      [
        'wordlist-dupes.html',
        'Duplicates',
        rikai_words.select {|w| w.flags_any? :dupe_in_anki, :dupe_in_rikai}
      ],
      [
        'wordlist-dupes-anki.html',
        '└─in Anki',
        rikai_words.select {|w| w.flags_all? :dupe_in_anki}
      ],
      [
        'wordlist-dupes-anki-alts.html',
        '&nbsp;&nbsp;└─in alts',
        rikai_words.select {|w| w.flags_all? :dupe_in_anki, :dupe_in_alts}
      ],
      [
        'wordlist-dupes-rikai.html',
        '└─in input',
        rikai_words.select {|w| w.flags_all? :dupe_in_rikai}
      ],
      [
        'wordlist-dupes-rikai-alts.html',
        '&nbsp;&nbsp;└─in alts',
        rikai_words.select {|w| w.flags_all? :dupe_in_rikai, :dupe_in_alts}
      ],
      [
        'wordlist-errors.html',
        'Errors',
        rikai_words.select {|w| w.error}
      ],
      [
        'wordlist-not-in-edict.html',
        '└─not in Edict',
        rikai_words.select {|w| w.flags_all? :not_in_edict}
      ]
    ]

    print "[Vocab] generating wordlists... "
    Progress.new(wordlists.size) do |pr|
      wordlists.each_with_index do |wl,i|
        make_wordlist wl[0], wl[1], wl[2], i
        pr.tick
      end
    end

    File.open($REPORTDIR+'/vocab-index.html','w:UTF-8') do |f|
      items = []
      wordlists.each_with_index do |wl,i|
        text = "#{wl[1]} (#{wl[2].size})"
        items << if wl[2].empty?
          $T['vocab/item-d.html'].with(
            TEXT: text
          )
        else
          $T['vocab/item.html'].with(
            URL: 'vocab-wordlists/' + wl[0],
            PAGEID: i,
            TEXT: text
          )
        end
      end
      f.write $T['vocab/index.html'].with(
        ITEMS: items.join("\n"),
        PAGECOUNT: wordlists.size
      )
    end
    
    File.open($REPORTDIR+'/vocab-wordlists/wordlist.css','w:UTF-8') do |f|
      f.write $T['vocab-flashcard/flashcard.css'].apply_ifdef('REPORT')
    end

    File.open('report-vocab.html','w') do |f|
      f.write $T['vocab/report.html'].with(REPORTDIR: $REPORTDIR)
    end
  end


  def Vocab.make_anki(rikai_words)
    rikai_words_good = rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                                   select {|w| !w.error}

    File.open('D:/vocab.[IMPORT].txt','w:UTF-8') do |f|
      rikai_words_good.each do |w|
        hash = Hash.new
        hash['expr'] = w.entries.first.expr
        hash['yomi'] = []
        w.entries.each_with_index do |e,i|
          kana = e.kana.dup
          kana = '~' + kana if !e.priority?
          kana = kana + '*' if i == 0
          alts = e.alts.map {|ar| ar.dup}
          if !Audio.have_file?(w.entries.first.expr, e.kana) &&
              alt_with_audio = alts[1].index {|a| Audio.have_file?(a.gsub('~',''), e.kana)}
            alts[1][alt_with_audio] += '*'
          end
          hash['yomi'] << {
            'kana' => kana,
            'alts' => alts,
            'eigo' => e.eigoc
          }
        end
        json = hash.to_json
        json.gsub! '"expr":', 'expr:'
        json.gsub! '"yomi":', 'yomi:'
        json.gsub! '"kana":', 'kana:'
        json.gsub! '"alts":', 'alts:'
        json.gsub! '"eigo":', 'eigo:'
        f.puts json.split('\"').join('\\\\\"').split("'").join("\\'") + "\t" + hash['expr']
      end
    end

  end


  def Vocab.make_vocab_list(anki_words, rikai_words)
    rikai_words_good = rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                                   select {|w| !w.error}

    (anki_words + rikai_words_good).map do |w|
      entries = w.xref ? w.xref.entries : w.entries
      expr = entries.first.expr
      w2 = Word.new
      w2.expr = expr
      w2.entries = entries
      w2
    end.freeze
  end

end # module
