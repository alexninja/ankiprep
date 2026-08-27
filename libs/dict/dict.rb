require 'fileutils'
require 'sqlite3'
require 'json'
require 'dict/kana'
require 'dict/yomi/parse'
require 'etc/progress'


module Dict

  @@markers = File.readlines(File.dirname(__FILE__)+'/edict_markers.txt').map {|line| line.split[0]}
  (1..100).to_a.each {|x| @@markers << x.to_s}

  JoinChar = Utf8::Space

  def Dict.kanjidic_size
    res = @@db.execute "SELECT COUNT(*) FROM kanjidic"
    res[0][0].to_i
  end

  def Dict.kanjidic_kanji?(k)
    res = @@db.execute "SELECT * FROM kanjidic WHERE kanji='#{k}'"
    res.count == 1
  end
  
  def Dict.kanjidic_yomi(k)
    res = @@db.execute <<-SQL
SELECT yomi.yomi
FROM yomi
JOIN j_kanji_yomi ON yomi.id = j_kanji_yomi.yomi_id
JOIN kanjidic ON kanjidic.id = j_kanji_yomi.kanjidic_id
WHERE kanjidic.kanji = '#{k}'
    SQL
    res.flatten
  end

  def Dict.edict_size
    res = @@db.execute "SELECT COUNT(*) FROM edict"
    res[0][0].to_i
  end

  def Dict.edict_each
    res = @@db.execute "SELECT * FROM edict"
    res.each do |row|
      entry = Entry.new(row[1], row[2], row[3])
      entry.eigoc = row[4]
      entry.alts = JSON::parse(row[5])
      entry.seki = JSON::parse(row[6])
      yield entry
    end
  end

  def Dict.edict_lookup(expr)
    res = @@db.execute "SELECT * FROM edict WHERE expr='#{expr}'"
    res.map do |row|
      entry = Entry.new(row[1], row[2], row[3])
      entry.eigoc = row[4]
      entry.alts = JSON::parse(row[5])
      entry.seki = JSON::parse(row[6])
      entry
    end
  end

  def Dict.edict_contains?(expr)
    res = @@db.execute "SELECT * FROM edict WHERE expr='#{expr}'"
    !res.empty?
  end

private

  def Dict.create_sqlite

    FileUtils.rm_f "#{$RES_DIR}/dict/dict.sqlite.tmp"
    @@db = SQLite3::Database.new("#{$RES_DIR}/dict/dict.sqlite.tmp")
    @@db.execute_batch File.read("../libs/dict/sqlite_create.txt")

    # kanjidic

    print "\n  reading #{$RES_DIR}/dict/kanjidic... "

    @@db.execute "BEGIN"
    Progress.new do |pr|
      lines = Utf8.readlines("#{$RES_DIR}/dict/kanjidic",'euc-jp')

      kanjidic_id = 1
      j_kanji_yomi_id = 1
      yomi_ids = Hash.new

      lines[1..-1].each do |line|
        id, kanji, eigo, heisig, stroke_count =
          kanjidic_id,
          line.split(' ')[0],
          Dict.kanjidic_eigo_(line).map {|e| e.gsub("'","''")}.to_json,
          Dict.kanjidic_heisig_(line),
          Dict.kanjidic_stroke_count_(line)
        @@db.execute "INSERT INTO kanjidic VALUES ('#{id}', '#{kanji}', '#{eigo}', '#{heisig}', '#{stroke_count}')"

        Dict.kanjidic_yomi_(line).each do |yomi|
          unless yomi_ids.has_key?(yomi)
            yomi_ids[yomi] = yomi_ids.size+1
            id = yomi_ids[yomi]
            @@db.execute "INSERT INTO yomi VALUES ('#{id}', '#{yomi}')"
          end
          id, yomi_id =
            j_kanji_yomi_id,
            yomi_ids[yomi]
          @@db.execute "INSERT INTO j_kanji_yomi VALUES ('#{id}', '#{kanjidic_id}', '#{yomi_id}')"
          j_kanji_yomi_id += 1
        end

        kanjidic_id += 1
        pr.tick
      end
    end
    @@db.execute "END"

    # p Dict.kanjidic_yomi('奥') #'鬥'
    # p Dict.kanjidic_yomi('八')
    # exit

#     puts @@db.execute <<-SQL
# SELECT yomi.yomi
# FROM yomi
# JOIN j_kanji_yomi ON yomi.id = j_kanji_yomi.yomi_id
# JOIN kanji ON kanji.id = j_kanji_yomi.kanji_id
# --where j_kanji_yomi.kanji_id = 3139
# WHERE kanji.kanji = '八'
# --ORDER BY yomi.yomi DESC
#     SQL
#     exit
@@db.close
FileUtils.mv "#{$RES_DIR}/dict/dict.sqlite.tmp", "#{$RES_DIR}/dict/dict.sqlite"
exit

    # edict

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
        entry.eigoc = Dict.edict_eigoc(entry)
        entry.alts = Dict.edict_alts(entry, expr_hash, kana_hash)
        entry.seki = Dict.edict_seki(entry)
        pr.tick
      end
    end

    @@db.execute "BEGIN"
    Progress.new(entries.size) do |pr|
      entries.each_with_index do |entry,idx|
        edict_id, expr, kana, eigo, eigoc, alts, seki =
          idx+1,
          entry.expr,
          entry.kana,
          entry.eigo.gsub("'","''"),
          entry.eigoc.gsub("'","''"),
          entry.alts.to_json,
          entry.seki.to_json
        cmd = "INSERT INTO edict VALUES ('#{edict_id}', '#{expr}', '#{kana}', '#{eigo}', '#{eigoc}', '#{alts}', '#{seki}')"
        @@db.execute cmd
        pr.tick
      end
    end
    @@db.execute "END"

    @@db.close #TODO no @@
    FileUtils.mv "#{$RES_DIR}/dict/dict.sqlite.tmp", "#{$RES_DIR}/dict/dict.sqlite"
  end

  def Dict.load!
    print "Loading dictionaries... "
    if !File.exist? "#{$RES_DIR}/dict/dict.sqlite"
      Dict.create_sqlite
    end
    @@db = SQLite3::Database.new("#{$RES_DIR}/dict/dict.sqlite", {flags: SQLite3::Constants::Open::READONLY})
  end

private

  # kanjidic helpers

  def Dict.kanjidic_eigo_(line)
    line.scan(/\{.*?\}/).map {|x| x[1..-2]}
  end

  def Dict.kanjidic_yomi_(line)
    yarr = []
    line.split(' ').each do |part|
      yarr << part if part.chars.any? {|x| x.kana?}
      break if part[0] == 'T' # up to nanori
    end
    yarr
  end

  def Dict.kanjidic_nanori(k)
    retval = []
    past_T = false
    line.split(' ').each do |part|
      if past_T
        retval << part if part.chars.any? {|x| x.kana?}
      else
        past_T = true if part[0] == 'T'
      end
    end
    retval
  end

  def Dict.kanjidic_heisig_(line)
    m = line.match(/\sL(\d{1,4})\s/)
    if m
      m[1].to_i
    else
      nil
    end
  end

  def Dict.kanjidic_stroke_count_(line)
    m = line.match(/\sS(\d{1,2})\s/)
    if m
      m[1].to_i
    else
      nil
    end
  end

  # edict helpers

  def Dict.edict_eigoc(entry)
    eigo = entry.eigo.dup
    eigo.scan(/\(.+?\)/).each do |part|
      if part[1..-2].split(',').all? {|p| @@markers.include? p}
        eigo.sub!(part, '')
        eigo.sub!('  ', ' ')
      end
    end
    eigo.split('/').delete_if {|x| x.empty?}.map {|x| x[0..0]==' ' ? x[1..-1] : x}.join('; ')
  end

  def Dict.edict_alts(entry, expr_hash, kana_hash)
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

  def Dict.edict_seki(entry)
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

  Dict.load!

end # module Dict

# class String
#   def kanji?
#     Dict.kanjidic_kanji?(self)
#   end
# end
