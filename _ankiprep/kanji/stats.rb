# encoding: UTF-8
require 'fileutils'
require 'set'
require 'json' # gem
require 'edict'
require 'kanjidic'
require 'kana'
require 'anki'
require 'misc/utf8'
require 'misc/utf16'
require 'misc/progress'
require 'yomi/parse'
require 'yomi/has_yomi'

ANK,POM,MON,EDI=0,1,2,3

$SOURCEDIR = if ARGV[0] == 'short'
  "__!sources!__/wordfreq_short"
else
  "__!sources!__/wordfreq_full"
end

module Stats

private

  Wordinfo = Struct.new(:expr, :n, :entries)


  def Stats.pre_init
    @valid_chars = Set.new
    Kanjidic.each_kanji {|k| @valid_chars << k}
    Kana.each_kana {|k| @valid_chars << k}
    @valid_chars << Utf8::Kurikaeshi
    @k, @yfreq = [], Hash.new
  end


  def Stats.parse_sources
    if File.exist? $SOURCEDIR+'/_marshal'
      print "[Stats] loading preparsed data... "
      Progress.new(1) do |pr|
        @k = File.open($SOURCEDIR+'/_marshal/k.marshal', "rb") {|f| Marshal.load(f)}
        @yfreq = File.open($SOURCEDIR+'/_marshal/yfreq.marshal', "rb") {|f| Marshal.load(f)}
        pr.tick
      end
      return
    end

    # POM, MON, EDI were not preparsed, parse now (and save for future runs)
    kw = add_source(POM, "#{$SOURCEDIR}/pomax/base_aggregates.txt") do |line|
      m = line.match(/(\d+)\t(.*)\t.+/)
      if m
        expr, n = m[2], m[1].to_i
        {expr => n}
      else
        nil
      end
    end
    @k[POM] = postprocess(kw)

    kw = add_source(MON, "#{$SOURCEDIR}/monash/wordfreq.utf8") do |line|
      m = line.match(/(.+)\+\d+\t(\d+)/)
      if m
        expr, n = m[1].split('+').last, m[2].to_i
        {expr => n}
      else
        nil
      end
    end
    @k[MON] = postprocess(kw)

    kw = add_source(EDI, "#{$SOURCEDIR}/goo/edict-freq-20081002") do |line|
      m = line.match(/(.+?) .+\/###(\d+)\//)
      if m
        expr, n = m[1], m[2].to_i
        {expr => n}
      else
        nil
      end
    end
    @k[EDI] = postprocess(kw)

    print "[Stats] saving preparsed data... "
    FileUtils.mkdir_p $SOURCEDIR+'/_marshal'
    Progress.new(1) do |pr|
      File.open($SOURCEDIR+'/_marshal/k.marshal', "wb") {|f| Marshal.dump(@k, f)}
      File.open($SOURCEDIR+'/_marshal/yfreq.marshal', "wb") {|f| Marshal.dump(@yfreq, f)}
      pr.tick
    end
  end


  def Stats.parse_anki
    errors_kanji = []

    print "[Stats] reading #{$ANKIDIR}/kanji.anki... "
    @known_kanji = Anki.read("#{$ANKIDIR}/kanji.anki").map do |kanji,json|
      json_q = json.gsub('use:',    '"use":'   ).
                    gsub('freq:',   '"freq":'  ).
                    gsub('words:',  '"words":' ).
                    gsub('other:',  '"other":' ).
                    gsub('yomi:',   '"yomi":'  ).
                    gsub('nanori:', '"nanori":').
                    gsub('eigo:',   '"eigo":'  ).
                    gsub('utf16:',  '"utf16":' ).
                    gsub('kanji:',  '"kanji":' ).
                    gsub('kjt:',    '"kjt":'   )
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

    puts "[Stats] parsing vocab..."
    kw = Hash.new {|h,k| h[k] = Set.new}
    @vocab_kanji = Set.new
    @relevant_kanji = Set.new
    Vocab.vocab_list.each do |w|
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

    puts "#{@vocab_kanji.size} kanji (#{(@vocab_kanji - @known_kanji).size} new)"
  end


  def Stats.add_source(src, filename)

    kw = Hash.new {|h,k| h[k] = Set.new}

    words = Hash.new

    # a half-hack to load all words from edict (to complement goo, which is really old)
    if src == EDI && $SOURCEDIR.include?("/__full__")
      print "[Stats] priming with Edict... "
      Progress.new(Edict.size) do |pr|
        Edict.each do |e|
          words[e.expr] = 0
        end
      end
    end

    print "[Stats] reading #{filename}... "
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

    print "[Stats] parsing #{words.size} words... "

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


  def Stats.postprocess(kw)
    print "[Stats] classifying... "

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


  def Stats.parse_kjt
    print "[Stats] reading kyuujitai list... "
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

  def Stats.words(src, k, yomi = :all)
    if @k[src][k]
      ret = @k[src][k][yomi]
    end
    ret || []
  end

  def Stats.yfreq(k, yomi)
    if @yfreq.has_key?(k) && @yfreq[k].has_key?(yomi)
      @yfreq[k][yomi]
    else
      0
    end
  end

  def Stats.yarr(k)
    ret = Kanjidic.yomi(k).delete_if {|yomi| yomi.include? '-'}
    if @yfreq.has_key? k
      ret = ret.sort_by {|yomi| yfreq(k,yomi)}.reverse.
            partition {|yomi| yomi.kat?}.flatten
    end
    ret
  end

  def Stats.valid_char?(c)
    @valid_chars.include? c
  end

  def Stats.known_kanji?(k)
    @known_kanji.include? k
  end

  def Stats.vocab_kanji?(k)
    @vocab_kanji.include? k
  end

  def Stats.all_kanji
    @vocab_kanji + @known_kanji
  end

  def Stats.new_kanji
    if Vocab.input_file_present?
      @vocab_kanji - @known_kanji
    else
      all_kanji
    end
  end

  def Stats.relevant_kanji
    if Vocab.input_file_present?
      @relevant_kanji  # kanji for which Wordlists will be regenerated
    else
      all_kanji
    end
  end

  def Stats.kjt(k)
    @kjt[k]
  end

  # module initialization

  def Stats.init
    pre_init
    parse_sources
    parse_anki
    parse_kjt
  end

end
