require 'dict/kana'
require 'etc/progress'

require 'sqlite3'
require 'json'


module Kanjidic

  # @yomi_cache = Hash.new

  # def Kanjidic.kanji?(k)
  #   @k.has_key?(k)
  # end

  # def Kanjidic.each_kanji
  #   @k.each_key {|k| yield k}
  # end

  def Kanjidic.size
    res = @@db.execute "SELECT COUNT(*) FROM kanji"
    res[0][0].to_i
  end

private

  def Kanjidic.create_sqlite

    FileUtils.rm_f "#{$RES_DIR}/dict/kanjidic.sqlite.tmp"
    db = SQLite3::Database.new("#{$RES_DIR}/dict/kanjidic.sqlite.tmp")

    db.execute "CREATE TABLE kanji (kanji_id INT PRIMARY KEY, kanji TEXT, eigo TEXT, heisig TEXT, stroke_count INT)"
    # db.execute "CREATE INDEX idx_kanjidic_kanji ON kanjidic (kanji)"
    db.execute "CREATE TABLE yomi (yomi_id INT PRIMARY KEY, yomi TEXT)"
    db.execute "CREATE TABLE kanji_yomi (kanji_id INT, yomi_id INT, PRIMARY KEY (kanji_id, yomi_id), FOREIGN KEY (kanji_id) REFERENCES kanji(kanji_id), FOREIGN KEY (yomi_id) REFERENCES yomi(yomi_id))"

    print "\n  reading #{$RES_DIR}/dict/kanjidic... "
    # lines = nil
    Progress.new do |pr|
      lines = Utf8.readlines("#{$RES_DIR}/dict/kanjidic",'euc-jp')
      yomi_hash = Hash.new {|h,k| h[k] = []}
      db.execute "BEGIN"
      lines[1..-1].each_with_index do |line,idx|
        kanji_id, kanji, yomi, eigo, heisig, stroke_count =
          idx+1,
          line.split(' ')[0],
          Kanjidic.yomi_(line),
          Kanjidic.eigo_(line).map {|e| e.gsub("'","''")}.to_json,
          Kanjidic.heisig_(line),
          Kanjidic.stroke_count_(line)
        cmd = "INSERT INTO kanji VALUES ('#{kanji_id}', '#{kanji}', '#{eigo}', '#{heisig}', '#{stroke_count}')"
        db.execute cmd
        yomi.each do |y|
          yomi_hash[y] << kanji_id
        end
        pr.tick
      end
      yomi_hash.keys.each_with_index do |y, idx|
        yomi_id, yomi, kanji_ids =
          idx+1,
          y,
          yomi_hash[y]
        cmd = "INSERT INTO yomi VALUES ('#{yomi_id}', '#{yomi}')"
        db.execute cmd
        kanji_ids.each do |kanji_id|
          cmd = "INSERT INTO kanji_yomi VALUES ('#{kanji_id}', '#{yomi_id}')"
          db.execute cmd
        end
      end
      db.execute "END"
    end

    db.close
    FileUtils.mv "#{$RES_DIR}/dict/kanjidic.sqlite.tmp", "#{$RES_DIR}/dict/kanjidic.sqlite"
  end

  def Kanjidic.load!
    print "Loading Kanjidic... "
    FileUtils.rm_f "#{$RES_DIR}/dict/kanjidic.sqlite"
    if !File.exist? "#{$RES_DIR}/dict/kanjidic.sqlite"
      Kanjidic.create_sqlite
    end
    @@db = SQLite3::Database.new("#{$RES_DIR}/dict/kanjidic.sqlite", {flags: SQLite3::Constants::Open::READONLY})
    puts "#{Kanjidic.size} entries in kanjidic.sqlite"
  end

  private

  def Kanjidic.eigo_(line)
    line.scan(/\{.*?\}/).map {|x| x[1..-2]}
  end

  def Kanjidic.yomi_(line)
    yarr = []
    line.split(' ').each do |part|
      yarr << part if part.chars.any? {|x| x.kana?}
      break if part[0] == 'T' # up to nanori
    end
    yarr
  end

  def Kanjidic.nanori_(k)
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

  def Kanjidic.heisig_(line)
    m = line.match(/\sL(\d{1,4})\s/)
    if m
      m[1].to_i
    else
      nil
    end
  end

  def Kanjidic.stroke_count_(line)
    m = line.match(/\sS(\d{1,2})\s/)
    if m
      m[1].to_i
    else
      nil
    end
  end

public

  Kanjidic.load!
  exit

end # module Kanjidic


# class String
#   def kanji?
#     Kanjidic.kanji?(self)
#   end
# end
