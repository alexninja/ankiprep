require 'dict/kanjidic'
require 'dict/yomi/parse'
require 'etc/progress'

module Edict

  @@expr = Hash.new {|hh,kk| hh[kk] = []}
  @@kana = Hash.new {|hh,kk| hh[kk] = []}

  @@markers = File.readlines(File.dirname(__FILE__)+'/edict_markers.txt').map {|line| line.split[0]}
  (1..100).to_a.each {|x| @@markers << x.to_s}

  def Edict.lookup_expr(expr)
    @@expr[expr]
  end

  def Edict.lookup_kana(kana)
    @@kana[kana]
  end

  def Edict.markers
    @@markers
  end

  JoinChar = Utf8::Space

  def Edict.each
    @@expr.each_value do |entries|
      entries.each do |entry|
        yield entry
      end
    end
  end

  def Edict.size
    @@expr.values.flatten.size
  end

  def Edict.contains?(expr)
    @@expr.has_key? expr
  end

private

  def Edict.load_marshaled
    if File.exist?($RES_DIR+"/.marshal/edict.marshal") &&
        File.stat($RES_DIR+"/.marshal/edict.marshal").mtime > File.stat($RES_DIR+'/edict/edict').mtime
      print "  unmarshaling... "
      Progress.new do |pr|
        @@expr, @@kana = File.open($RES_DIR+"/.marshal/edict.marshal", "rb") {|f| Marshal.load(f)}
      end
    end
  end

  def Edict.save_marshaled
    print "  marshaling... "
    Progress.new do |pr|
      @@expr.default = nil
      @@kana.default = nil
      File.open($RES_DIR+"/.marshal/edict.marshal", "wb") {|f| Marshal.dump([@@expr,@@kana], f)}
    end
  end

  def Edict.load_from_file
    print "  reading file... "
    lines = nil
    Progress.new do |pr|
      lines = Utf8.readlines($RES_DIR+'/edict/edict','euc-jp')
    end

    File.open($RES_DIR+'/edict/edict.utf8','w') {|f| lines.each {|line| f.puts line}}

    print "  parsing #{lines.size-1} lines... "
    entries = []
    Progress.new(lines.size-1) do |pr|
      lines[1..-1].each_with_index do |line,i|
        if m = line.match(/(.+?) \[(.+?)\] (\/.+\/)/)
          entry = Entry.new(m[1], m[2], m[3])
        elsif m = line.match(/(.+?) (\/.+\/)/)
          entry = Entry.new(m[1], m[1], m[2])
        end
        if entry
          entries << entry
          @@expr[entry.expr] << entry
          @@kana[entry.kana] << entry
        end
        pr.tick
      end
    end

    print "  classifying #{entries.size} entries... "
    Progress.new(entries.size) do |pr|
      entries.each do |entry|
        entry.eigoc = entry.eigoc_()
        entry.alts = entry.alts_()
        entry.seki = entry.seki_()
        pr.tick
      end
    end

  end

  def Edict.load!
    puts "Loading Edict... "
    load_marshaled
    if @@expr.empty? && @@kana.empty?
      load_from_file
      save_marshaled
    end
  end


#-----

public class Entry

    attr_reader :expr, :kana, :eigo
    attr_writer :priority, :fake
    attr_accessor :eigoc, :alts, :seki

    def initialize(expr, kana, eigo)
      @expr, @kana, @eigo = expr, kana, eigo
      [@expr, @kana, @eigo].each {|v| v.freeze}
      @priority = @eigo.include? '(P)'
      @fake = false
      @eigoc = nil
      @alts = nil
      @seki = nil
    end

    def eigoc_
      e = @eigo.dup
      e.scan(/\(.+?\)/).each do |part|
        if part[1..-2].split(',').all? {|p| Edict.markers.include? p}
          e.sub!(part, '')
          e.sub!('  ', ' ')
        end
      end
      e.split('/').delete_if {|x| x.empty?}.map {|x| x[0..0]==' ' ? x[1..-1] : x}.join('; ')
    end

    def alts_
      # find alternate kana for [@expr,@eigoc] (if any), and alternate expr's for [@kana,@eigoc] (if any)
      # result is an array of two arrays of strings; non-priority strings prefixed with '~'
      # e.g. for 言う いう returns: [["ゆう"], ["~謂う","~云う"]]
      [
        Edict.lookup_expr(@expr).
          select {|entry| entry.eigoc == @eigoc && entry.kana != @kana}.
          partition {|entry| entry.priority?}.
          flatten.
          map {|entry| (entry.priority?) ? entry.kana : '~'+entry.kana} ,
        Edict.lookup_kana(@kana).
          select {|entry| entry.eigoc == @eigoc && entry.expr != @expr}.
          partition {|entry| entry.priority?}. # TODO partition(&:priority?)
          flatten.
          map {|entry| (entry.priority?) ? entry.expr : '~'+entry.expr}
      ]
    end

    def seki_
      Yomi.parse(self)
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

#-----

  Edict.load!

end # module Edict
