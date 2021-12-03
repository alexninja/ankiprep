require 'misc/progress'
require 'misc/utf8'

module Edict

  class Entry
    attr_reader :expr, :kana, :eigo
    attr_writer :alts, :priority, :fake  # to accommodate creation of fake Entries

    @@markers = File.readlines(File.dirname(__FILE__)+'/edict_markers.txt').map {|line| line.split[0]}
    (1..100).to_a.each {|x| @@markers << x.to_s}

    def initialize(expr, kana, eigo)
      @expr, @kana, @eigo = expr, kana, eigo
      [@expr, @kana, @eigo].each {|v| v.freeze}
      @priority = @eigo.include? '(P)'
      @eigoc = nil
      @seki = nil
      @alts = nil
      @fake = false
    end

    def eigoc  #lazy
      return @eigoc if @eigoc
      e = @eigo.dup
      e.scan(/\(.+?\)/).each do |part|
        if part[1..-2].split(',').all? {|p| @@markers.include? p}
          e.sub!(part, '')
          e.sub!('  ', ' ')
        end
      end
      @eigoc = e.split('/').delete_if {|x| x.empty?}.map {|x| x[0..0]==' ' ? x[1..-1] : x}.join('; ')
    end

    def seki  #lazy
      # NB assumes 'yomi/parse' was already require'd by calling code ! ! !
      @seki ||= Yomi.parse(self)
    end

    def alts  #lazy
      # find alternate kana for [@expr,@eigoc] (if any), and alternate expr's for [@kana,@eigoc] (if any)
      # result is an array of two arrays of strings; non-priority strings prefixed with '~'
      # e.g. for 言う いう returns: [["ゆう"], ["~謂う","~云う"]]
      @alts ||= [
        Edict.lookup_expr(@expr).
          select {|e| e.eigoc == self.eigoc && e.kana != @kana}.
          partition {|e| e.priority?}.
          flatten.
          map {|e| (e.priority?) ? e.kana : '~'+e.kana} ,
        Edict.lookup_kana(@kana).
          select {|e| e.eigoc == self.eigoc && e.expr != @expr}.
          partition {|e| e.priority?}.
          flatten.
          map {|e| (e.priority?) ? e.expr : '~'+e.expr}
      ]
    end

    def ==(other)
      @expr == other.expr and @kana == other.kana and @eigoc == other.eigoc
    end

    def priority?
      @priority
    end

    def fake?
      @fake
    end

    def priority=(forcepr)
      @priority = forcepr
    end

    # for use as a Hash key

    def hash
      [expr, kana].hash
    end

    def eql? other
      [expr, kana] == [other.expr, other.kana]
    end

  end # class Entry

  def Entry.from(line)
    return line if line.class == Edict::Entry #HACK!
    if m = line.match(/(.+?) \[(.+?)\] (\/.+\/)/)
      Entry.new(m[1], m[2], m[3])
    elsif m = line.match(/(.+?) (\/.+\/)/)
      Entry.new(m[1], m[1], m[2])
    else
      raise "something awful happened"
    end
  end

#-----

  JoinChar = Utf8::Space

  def Edict.lookup_expr(expr)
    arr = (@e[expr] || [])
    if !arr.empty? && arr[0].class == String
      @e[expr] = arr.map {|line| Entry.from(line)}
    else
      arr
    end
  end

  def Edict.lookup_kana(kana)
    arr = (@k[kana] || [])
    if !arr.empty? && arr[0].class == String
      @k[kana] = arr.map {|line| Entry.from(line)}
    else
      arr
    end
  end

  def Edict.each
    @e.each_value do |lines|
      lines.each do |line|
        yield Entry.from(line)
      end
    end
  end

  def Edict.size
    @e.values.flatten.size
  end

  # find expressions with alternative spelling but same kana+eigo (e.g. "au" to meet)
  # NB this was only used in ankiprep, seems obsolete now that I'm focusing on kanjibig
  def Edict.lookup(expr, kana)
    return [] unless @e.has_key? expr
    list = []
    entries = @e[expr].map {|line| Entry.from(line)}
    anypr = entries.any? {|e| e.priority?}
    if kana
      entries.each {|e| e.priority=true if e.expr==expr and e.kana==kana}
    elsif !entries.any? {|e| e.priority?}
      entries[0].priority=true
    end
    entries.each do |entry|
      list << entry
      next if anypr and not entry.priority?
      @k[entry.kana].each do |samek_line|
        samek_entry = Entry.from(samek_line)
        if samek_entry.eigoc == entry.eigoc
          list << samek_entry unless list.include? samek_entry
        end
      end
    end
    if kana && !list.any? {|e| e.expr==expr and e.kana==kana}
      list.insert(0, Entry.new(expr, kana, ''))
      list[0].priority=true
    end
    list
  end

  # NB this was only used in ankiprep, seems obsolete now that I'm focusing on kanjibig
  def Edict.merge(lst)
    # merge entries that share same [expr] or same [kana,eigoc]
    # also add non-priority markers (~)
    list = lst.dup
    (0..list.size-2).each do |i|
      next unless list[i]
      (list.size-i-1).times do
        (i+1..list.size-1).each do |j|
          next unless list[j]
          if share?(:expr, list[i], list[j]) or (share?(:kana, list[i], list[j]) and share?(:eigoc, list[i], list[j]))
            list[i] = [list[i]].flatten << list[j]
            list[i].flatten!
            list[j] = nil
          end
        end
      end #times
    end
    ret = list.compact.map do |x|
      pr, np = [x].flatten.partition {|e| e.priority?}

      expr = pr.map {|e| e.expr}.uniq
      np.each {|e| expr << '~'+e.expr unless expr.include? e.expr or expr.include? '~'+e.expr}
      expr = expr.join(JoinChar)

      kana = pr.map {|e| e.kana}.uniq
      np.each {|e| kana << '~'+e.kana unless kana.include? e.kana or kana.include? '~'+e.kana}
      kana = kana.join(JoinChar)
        
      Merged.new(expr, kana)
    end
    raise 'Edict.merge > 1' if ret.size > 1
    ret[0]
  end

  def Edict.contains?(expr)
    @e.has_key? expr
  end

private

  EdictMarshal = Struct.new(:e,:k)

  def Edict.preparse
    e = Hash.new {|hh,kk| hh[kk] = []}
    k = Hash.new {|hh,kk| hh[kk] = []}

    print "preparsing... "

    lines = Utf8.readlines($DICT_DIR+'/edict/edict','euc-jp')

    # save a copy of edict as utf-8 purely for convenience
    File.open($DICT_DIR+'/edict/edict.utf8','w') {|f| lines.each {|line| f.puts line}}

    lines[1..-1].each_with_index do |line,i|
      if m = line.match(/(.+?) \[(.+?)\] (\/.+\/)/)
        e[m[1]] << line
        k[m[2]] << line
      elsif m = line.match(/(.+?) (\/.+\/)/)
        e[m[1]] << line
        k[m[1]] << line
      else
        puts "skipping bad edict line (#{i+1}): `#{line}`"
      end
    end

    e.default = nil
    k.default = nil
    File.open($DICT_DIR+"/edict/edict.marshal", "wb") {|f| Marshal.dump(EdictMarshal.new(e,k), f)}
  end

  def Edict.load!
    print "Loading Edict... "
    Progress.new do |pr|
      preparse unless File.exist?($DICT_DIR+"/edict/edict.marshal")
      edict_marshal = File.open($DICT_DIR+"/edict/edict.marshal", "rb") {|f| Marshal.load(f)}
      @e = edict_marshal.e
      @k = edict_marshal.k
    end
  end

  #do these two entries/lists of entries share the same field(s)?
  def Edict.share?(field, e1, e2)
    f1 = [e1].flatten.map {|e| e.send(field)}.uniq
    f2 = [e2].flatten.map {|e| e.send(field)}.uniq
    return (f1 - f2).size < f1.size
  end

  load!

private

  Merged = Struct.new(:expr, :kana)

end #module
