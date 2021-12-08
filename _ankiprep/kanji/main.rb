# encoding: UTF-8
require 'set'
require 'FileUtils'
require 'json' # gem
require 'edict'
require 'kanjidic'
require 'kana'
require 'anki'
require 'misc/utf8'
require 'misc/utf16'
require 'misc/progress'
require 'misc/template'
require 'misc/urlify'
require 'yomi/parse'
require 'yomi/has_yomi'
require_relative 'wordlist/format'
require_relative 'flashcard/format'
require_relative 'report/report'


module Kanji

  def self.makeall
    Kanji::Stats.init
    Kanji::Flashcard.makeall
    Kanji::Wordlist.makeall
    Kanji::Report.make_htmls
  end

end


##################################################

ANK,POM,MON,EDI=0,1,2,3

$WORDFREQ_DIR = "__!sources!__/wordfreq"


module Kanji; module Stats

private

  Wordinfo = Struct.new(:expr, :n, :entries)


  def self.pre_init
    @valid_chars = Set.new
    Kanjidic.each_kanji {|k| @valid_chars << k}
    Kana.each_kana {|k| @valid_chars << k}
    @valid_chars << Utf8::Kurikaeshi
    @k, @yfreq = [], Hash.new
  end


  def self.parse_sources
    if File.exist? $WORDFREQ_DIR+'/_marshal'
      print "[Kanji::Stats] loading preparsed data... "
      Progress.new(1) do |pr|
        @k = File.open($WORDFREQ_DIR+'/_marshal/k.marshal', "rb") {|f| Marshal.load(f)}
        @yfreq = File.open($WORDFREQ_DIR+'/_marshal/yfreq.marshal', "rb") {|f| Marshal.load(f)}
        pr.tick
      end
      return
    end

    # POM, MON, EDI were not preparsed, parse now (and save for future runs)
    kw = add_source(POM, "#{$WORDFREQ_DIR}/pomax/base_aggregates.txt") do |line|
      m = line.match(/(\d+)\t(.*)\t.+/)
      if m
        expr, n = m[2], m[1].to_i
        {expr => n}
      else
        nil
      end
    end
    @k[POM] = postprocess(kw)

    kw = add_source(MON, "#{$WORDFREQ_DIR}/monash/wordfreq.utf8") do |line|
      m = line.match(/(.+)\+\d+\t(\d+)/)
      if m
        expr, n = m[1].split('+').last, m[2].to_i
        {expr => n}
      else
        nil
      end
    end
    @k[MON] = postprocess(kw)

    kw = add_source(EDI, "#{$WORDFREQ_DIR}/goo/edict-freq-20081002") do |line|
      m = line.match(/(.+?) .+\/###(\d+)\//)
      if m
        expr, n = m[1], m[2].to_i
        {expr => n}
      else
        nil
      end
    end
    @k[EDI] = postprocess(kw)

    print "[Kanji::Stats] saving preparsed data... "
    FileUtils.mkdir_p $WORDFREQ_DIR+'/_marshal'
    Progress.new(1) do |pr|
      File.open($WORDFREQ_DIR+'/_marshal/k.marshal', "wb") {|f| Marshal.dump(@k, f)}
      File.open($WORDFREQ_DIR+'/_marshal/yfreq.marshal', "wb") {|f| Marshal.dump(@yfreq, f)}
      pr.tick
    end
  end


  def self.parse_anki
    errors_kanji = []

    print "[Kanji::Stats] reading #{$ANKIDIR}/kanji.anki... "
    @known_kanji = Anki.read("#{$ANKIDIR}/kanji.anki").map do |kanji,json|
      json_q = json.
        gsub('comp_rank:', '"comp_rank":').
        gsub('comp_freq:', '"comp_freq":').
        gsub('use:',       '"use":'      ).
        gsub('freq:',      '"freq":'     ).
        gsub('words:',     '"words":'    ).
        gsub('yomi:',      '"yomi":'     ).
        gsub('nanori:',    '"nanori":'   ).
        gsub('eigo:',      '"eigo":'     ).
        gsub('utf16:',     '"utf16":'    ).
        gsub('kanji:',     '"kanji":'    ).
        gsub('kjt:',       '"kjt":'      ).
        gsub('other:',     '"other":'    )
      if kanji != JSON.parse(json_q)['kanji']
        errors_kanji << "mismatch: [#{kanji.inspect}] | " + JSON.parse(json_q)['kanji']
#        errors_kanji << json
      end
      kanji.chomp
    end.to_set
    puts "#{@known_kanji.size} known kanji"

    if errors_kanji.size > 0
      File.open('__errors.txt','w:UTF-8') do |f|
        f.puts "*** #{errors_kanji.size} errors in #{$ANKIDIR}/kanji.anki ***"
        errors_kanji.each {|err| f.puts err}
      end
      abort "Errors in kanji.anki! [see __errors.txt]" #abort
    end

    puts "[Kanji::Stats] parsing vocab..."
    kw = Hash.new {|h,k| h[k] = Set.new}
    @vocab_kanji = Set.new
    @relevant_kanji = Set.new
    (Vocab.vocab_list || []).each do |w|
      wordinfo = Wordinfo.new(w.expr, 1, w.entries)
      kanji_in_word = w.expr.chars.select {|c| c.kanji?}
      kanji_in_word.each do |k|
        kw[k] << wordinfo
        @vocab_kanji << k
      if kanji_in_word.any? {|k| !known_kanji?(k)}
        kanji_in_word.each {|k| @relevant_kanji << k}
      end
      end
    end

    @k[ANK] = postprocess(kw)

    puts "[Kanji::Stats] #{@vocab_kanji.size} kanji (#{(@vocab_kanji - @known_kanji).size} new)"
  end


  def self.add_source(src, filename)

    puts "[Kanji::Stats] adding word frequency source: " + %w[ANK POM MON EDI][src]

    kw = Hash.new {|h,k| h[k] = Set.new}

    words = Hash.new {|h,k| h[k] = 0}

    print "[Kanji::Stats] reading #{filename}... "
    lines = Utf8.readlines(filename)

    Progress.new(lines.size) do |pr|
      lines.each do |line|

        next if line.empty?
        r = yield line
        next unless r.class == Hash

        r.each do |expr,n|
          chars = expr.chars
          next unless (chars.all? {|c| @valid_chars.include? c} &&
                       chars.any? {|c| c.kanji?} &&
                       Edict.contains?(expr))
          words[expr] = n
        end

        pr.tick
      end
    end

    # EDICT has grown since; throw in everything not covered by goo
    if src == EDI
      print "[Kanji::Stats] adding newer Edict entries... "
      Progress.new(Edict.size) do |pr|
        Edict.each do |e|
          words[e.expr] = 1 if !words.has_key?(e.expr)
        end
      end
    end

    print "[Kanji::Stats] parsing #{words.size} words... "

    Progress.new(words.size) do |pr|
      words.each do |expr,n|

        entries = Edict.lookup_expr(expr)
        wordinfo = Wordinfo.new(expr, n, entries)

        expr.chars.select {|c| c.kanji?}.each do |k|
          kw[k] << wordinfo
        end

        pr.tick
      end
    end

    kw
  end


  def self.postprocess(kw)
    print "[Kanji::Stats] classifying... "

    k_src = Hash.new {|hk,_| hk[_] = Hash.new {|hy,_| hy[_] = []}}

    Progress.new(kw.size) do |pr|

      kw.each_key do |k|
        sorted = kw[k].to_a.sort_by {|wi| wi.n}.reverse
        k_src[k][:all] = sorted

        # would have called it 'yarr' but that clashes with a member function which can't work yet
        yomiarr = Kanjidic.yomi(k).delete_if {|yomi| yomi.include? '-'}

        sorted.each do |wi|
          # whatever reading(s) of this word match a particular yomi, save them under that yomi.
          # keep track of which ones did not match any yomi... (*)
          covered = [false] * wi.entries.size
          yomiarr.each do |yomi|
            matches = wi.entries.map {|e| Yomi.has_yomi?(e.seki, k, yomi)}
            if matches.any? {|x| x == true}
              k_src[k][yomi] << Wordinfo.new(wi.expr, wi.n, wi.entries.select.with_index {|e,i| matches[i]})
              matches.each_with_index {|x,i| covered[i] |= x}
              # @yfreq may have been unmarshaled, thus no default handlers
              @yfreq[k] = Hash.new unless @yfreq.has_key? k
              @yfreq[k][yomi] = 0 unless @yfreq[k].has_key? yomi
              @yfreq[k][yomi] += (wi.n > 0 ? wi.n : 1)
            end
          end
          # (*)... and save them under 'other'
          if covered.any? {|x| x == false}
            k_src[k][:other] << Wordinfo.new(wi.expr, wi.n, wi.entries.select.with_index {|e,i| !covered[i]})
          end
        end

        pr.tick
      end

    end

    k_src.default = nil
    k_src.each_key do |k|
      k_src[k].default = nil
    end

    k_src
  end


  def self.parse_kjt
    print "[Kanji::Stats] reading kyuujitai list... "
    @kjt = Hash.new {|h,k| h[k] = ''}
    File.read('__!sources!__/kjt/asahi/old_chara.html', mode:'r:Shift_JIS:UTF-8')
        .scan(/\s+<td class="ch">(.+)<\/td>\n\s+<td class="ch">(.+)<\/td>/)
        .each do |new,old|
          old = old[3..6].charfrom_utf16 if old.match(/&#x.{4};/)
          @kjt[old] << new
        end
    puts "#{@kjt.size} old kanji"
  end


public

  def self.words(src, k, yomi = :all)
    if @k[src][k]
      ret = @k[src][k][yomi]
    end
    ret || []
  end

  def self.yfreq(k, yomi)
    if @yfreq.has_key?(k) && @yfreq[k].has_key?(yomi)
      @yfreq[k][yomi]
    else
      0
    end
  end

  def self.yarr(k)
    ret = Kanjidic.yomi(k).delete_if {|yomi| yomi.include? '-'}
    if @yfreq.has_key? k
      ret = ret.sort_by {|yomi| yfreq(k,yomi)}.reverse.
            partition {|yomi| yomi.kat?}.flatten
    end
    ret
  end

  def self.valid_char?(c)
    @valid_chars.include? c
  end

  def self.known_kanji?(k)
    @known_kanji.include? k
  end

  def self.vocab_kanji?(k)
    @vocab_kanji.include? k
  end

  def self.all_kanji
    @vocab_kanji + @known_kanji
  end

  def self.new_kanji
    if Vocab.input_file_present?
      @vocab_kanji - @known_kanji
    else
      all_kanji
    end
  end

  def self.relevant_kanji
    if Vocab.input_file_present?
      @relevant_kanji  # kanji for which Wordlists will be regenerated
    else
      all_kanji
    end
  end

  def self.kjt(k)
    @kjt[k]
  end

  # module initialization

  def self.init
    pre_init
    parse_sources
    parse_anki
    parse_kjt
  end

end; end
