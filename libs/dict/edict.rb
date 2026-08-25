require 'fileutils'
require 'dict/kanjidic'
require 'dict/yomi/parse'
require 'etc/progress'

require 'sqlite3'
require 'json'


module Edict

  @@markers = File.readlines(File.dirname(__FILE__)+'/edict_markers.txt').map {|line| line.split[0]}
  (1..100).to_a.each {|x| @@markers << x.to_s}

  JoinChar = Utf8::Space

  def Edict.each
    res = @@db.execute "SELECT * FROM edict"
    res.each do |row|
      entry = Entry.new(row[0], row[1], row[2])
      entry.eigoc = row[3]
      entry.alts = JSON::parse(row[4])
      entry.seki = JSON::parse(row[5])
      yield entry
    end
  end

  def Edict.lookup_expr(expr)
    res = @@db.execute "SELECT * FROM edict WHERE expr='#{expr}'"
    res.map do |row|
      entry = Entry.new(row[0], row[1], row[2])
      entry.eigoc = row[3]
      entry.alts = JSON::parse(row[4])
      entry.seki = JSON::parse(row[5])
      entry
    end
  end

  def Edict.contains?(expr)
    res = @@db.execute "SELECT * FROM edict WHERE expr='#{expr}'"
    !res.empty?
  end

  def Edict.size
    res = @@db.execute "SELECT COUNT(*) FROM edict"
    res[0][0].to_i
  end


private

  def Edict.load!
    print "Loading Edict... "

    # TODO READONLY for duration
    if File.exist? "#{$RES_DIR}/dict/edict.sqlite"
      @@db = SQLite3::Database.new("#{$RES_DIR}/dict/edict.sqlite", {flags: SQLite3::Constants::Open::READONLY})
      puts "#{Edict.size} entries in edict.sqlite"
      return
    end

    @@db = SQLite3::Database.new("#{$RES_DIR}/dict/edict.sqlite")
    @@db.execute "CREATE TABLE edict (expr TEXT, kana TEXT, eigo TEXT, eigoc TEXT, alts TEXT, seki TEXT)"
    @@db.execute "CREATE INDEX idx_edict_expr ON edict (expr)"

    print "\n  reading #{$RES_DIR}/dict/edict... "
    lines = nil
    Progress.new do |pr|
      lines = Utf8.readlines("#{$RES_DIR}/dict/edict",'euc-jp')
      #lines = Utf8.readlines("#{$RES_DIR}/dict/edict.utf8")
    end

    #File.open($RES_DIR+'/dict/edict.utf8','w') {|f| lines.each {|line| f.puts line}}

    expr_hash = Hash.new {|hh,kk| hh[kk] = []}
    kana_hash = Hash.new {|hh,kk| hh[kk] = []}
  
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
          expr_hash[entry.expr] << entry
          kana_hash[entry.kana] << entry
        end
        pr.tick
      end
    end

    print "  classifying #{entries.size} entries... "
    Progress.new(entries.size) do |pr|
      entries.each do |entry|
        entry.eigoc = Edict.eigoc(entry)
        entry.alts = Edict.alts(entry, expr_hash, kana_hash)
        entry.seki = Edict.seki(entry)
        pr.tick
      end
    end

    print "  writing edict.sqlite... "
    @@db.execute "BEGIN"
    Progress.new(entries.size) do |pr|
      entries.each do |entry|
        expr, kana, eigo, eigoc, alts, seki =
          entry.expr,
          entry.kana,
          entry.eigo.gsub("'","''"),
          entry.eigoc.gsub("'","''"),
          entry.alts.to_json,
          entry.seki.map {|s| [s.yomi,s.frag,s.moji]}.to_json
        cmd = "INSERT INTO edict VALUES ('#{expr}', '#{kana}', '#{eigo}', '#{eigoc}', '#{alts}', '#{seki}')"
        @@db.execute cmd
        pr.tick
      end
    end
    @@db.execute "END"

  end

private

  def Edict.eigoc(entry)
    eigo = entry.eigo.dup
    eigo.scan(/\(.+?\)/).each do |part|
      if part[1..-2].split(',').all? {|p| @@markers.include? p}
        eigo.sub!(part, '')
        eigo.sub!('  ', ' ')
      end
    end
    eigo.split('/').delete_if {|x| x.empty?}.map {|x| x[0..0]==' ' ? x[1..-1] : x}.join('; ')
  end

  def Edict.alts(entry, expr_hash, kana_hash)
    # find alternate kana for [expr,eigoc] (if any), and alternate expr's for [kana,eigoc] (if any)
    # result is an array of two arrays of strings; non-priority strings prefixed with '~'
    # e.g. for 言う いう returns: [["ゆう"], ["~謂う","~云う"]]
    expr, kana, eigoc = entry.expr, entry.kana, entry.eigoc
    [
      expr_hash[expr].
        select {|e| e.eigoc == eigoc && e.kana != kana}.
        partition(&:priority?).flatten.
        map {|e| (e.priority?) ? e.kana : '~'+e.kana} ,
      kana_hash[kana].
        select {|e| e.eigoc == eigoc && e.expr != expr}.
        partition(&:priority?).flatten.
        map {|e| (e.priority?) ? e.expr : '~'+e.expr}
    ]
  end

  def Edict.seki(entry)
    Yomi.parse(entry)
  end

#-----

public

  class Entry

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

    def priority?
      @priority
    end

    def fake?
      @fake
    end

  end # class Entry

#-----

  Edict.load!

end # module Edict
