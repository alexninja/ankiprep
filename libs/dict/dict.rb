require 'fileutils'
require 'sqlite3'
require 'json'
require 'dict/kana'
require 'dict/yomi/parse'
require 'dict/yomi/rendaku'
require 'etc/progress'


module Dict

  @@markers = File.readlines(File.dirname(__FILE__)+'/edict_markers.txt').map {|line| line.split[0]}
  (1..100).to_a.each {|x| @@markers << x.to_s}

  JoinChar = Utf8::Space

  # def Dict.kanjidic_size
  #   res = @@db.execute "SELECT COUNT(*) FROM kanjidic"
  #   res[0][0].to_i
  # end

  def Dict.kanjidic_kanji?(k)
    res = @@db.execute "SELECT COUNT(*) FROM seki WHERE seki.moji='#{k}'"
    res[0][0].to_i > 0
  end
  
  def Dict.kanjidic_yomi(k)
    res = @@db.execute "SELECT seki.yomi FROM seki WHERE seki.moji='#{k}'"
    res.flatten.uniq
  end

  def Dict.edict_size
    res = @@db.execute "SELECT COUNT(*) FROM edict"
    res[0][0].to_i
  end

  def Dict.edict_each
    res = @@db.execute "SELECT * FROM edict"
    res.each do |expr, kana, eigo, prio|
      yield Entry.new(expr, kana, eigo, prio)
    end
  end

  def Dict.edict_lookup(expr)
    res = @@db.execute "SELECT * FROM edict WHERE expr='#{expr}'"
    res.map do |expr, kana, eigo, prio|
      Entry.new(expr, kana, eigo, prio)
    end
  end

  def Dict.edict_contains?(expr)
    res = @@db.execute "SELECT * FROM edict WHERE expr='#{expr}'"
    !res.empty?
  end

  def Dict.seki(expr)
    #for regression checking
    @@db4 ||= SQLite3::Database.new("#{$RES_DIR}/.sqlite/dict.4.sqlite", {flags: SQLite3::Constants::Open::READONLY})
    puts "--- (from previous dict4.sqlite) ---------------------------------------------------"
    puts @@db4.execute "SELECT expr, kana, seki FROM edict WHERE expr='#{expr}'"
    puts "------------------------------------------------------------------------------------"
    entries = Dict.edict_lookup(expr)
    return if entries.empty?
    entries.each {|e| puts "{ #{e.expr} #{e.kana} \"#{e.eigo}\" }"}
    seki_candidate_rows = expr.chars.to_a.map.with_index do |moji,i|
      candidate_row = []
      res = @@db.execute "SELECT * FROM yomi WHERE yomi.moji='#{moji}'"
      if res.empty?
        candidate_row << [moji, moji, moji]
      else
        res.each do |moji, yomi|
          frag = yomi.split('.')[0].to_hir
          candidate_row << [moji, yomi, frag]
          Yomi.rendakuh(frag).each {|fragh| candidate_row << [moji, yomi, fragh]} unless i == 0
          Yomi.rendakut(frag).each {|fragt| candidate_row << [moji, yomi, fragt]} unless i == expr.length-1
        end
      end
      candidate_row
    end
    seki_candidate_rows.each {|scr| p scr}
    entries.each do |entry|
      puts "looking for #{entry.kana}..."
      find_seki_rec(entry.kana, seki_candidate_rows, []) do |accum_seki_arr|
        raise unless entry.kana == accum_seki_arr.map {|s| s[2]}.join('')
        puts "===> got:"
        accum_seki_arr.each {|s| p s}
        # puts "{\"#{entry.expr}\", \"#{entry.kana}\", \"#{entry.eigo}\"}"
        # puts '---------'
      end
    end
    # puts "total #{seki_arr_n} seki sets considered"
  end

private

  def Dict.find_seki_rec(kana, seki_candidate_rows, accum_seki_arr, &block)
    kana_so_far = accum_seki_arr.map {|s| s[2]}.join('')
    return if !kana.start_with?(kana_so_far)
    if kana == kana_so_far
      block.call(accum_seki_arr)
      return
    end
    seki_candidate_rows[0].each do |scr|
      find_seki_rec(kana, seki_candidate_rows[1..-1], accum_seki_arr+[scr], &block)
    end
  end

private

  def Dict.create_sqlite

    FileUtils.mkdir_p "#{$RES_DIR}/.sqlite"
    FileUtils.rm_f "#{$RES_DIR}/.sqlite/dict.sqlite.tmp"
    @@db = SQLite3::Database.new("#{$RES_DIR}/.sqlite/dict.sqlite.tmp")
    @@db.execute_batch File.read("../libs/dict/create_tables.sql")

    # kanjidic

    print "  reading #{$RES_DIR}/dict/kanjidic... "
    lines = nil
    Progress.new do |pr|
      lines = Utf8.readlines("#{$RES_DIR}/dict/kanjidic",'euc-jp')
      File.open($RES_DIR+'/dict/kanjidic.utf8','w') {|f| lines.each {|line| f.puts line}}
    end

    print "  writing .sqlite... "
    @@db.execute "BEGIN"
    Progress.new(lines.size-1) do |pr|
      lines[1..-1].each do |line|
        moji = line.split(' ')[0]
        eigo, heisig, stroke_count =
          Dict.kanjidic_eigo_from_line(line).map {|e| e.gsub("'","''")}.to_json,
          Dict.kanjidic_heisig_from_line(line),
          Dict.kanjidic_stroke_count_from_line(line)
        @@db.execute "INSERT INTO kanji VALUES ('#{moji}', '#{eigo}', '#{heisig}', '#{stroke_count}')"
        Dict.kanjidic_yomi_from_line(line).each do |yomi|
          @@db.execute "INSERT OR IGNORE INTO yomi VALUES ('#{moji}', '#{yomi}')"
        end
        pr.tick
      end
    end
    @@db.execute "END"

    # edict

    print "  reading #{$RES_DIR}/dict/edict... "
    lines = nil
    Progress.new do |pr|
      lines = Utf8.readlines("#{$RES_DIR}/dict/edict",'euc-jp')
      File.open($RES_DIR+'/dict/edict.utf8','w') {|f| lines.each {|line| f.puts line}}
    end

    print "  parsing #{lines.size-1} lines... "
    entries = []
    Progress.new(lines.size-1) do |pr|
      lines[1..-1].each_with_index do |line,i|
        if m = line.match(/(.+?) \[(.+?)\] (\/.+\/)/)
          expr, kana, eigo_raw = m[1], m[2], m[3]
        elsif m = line.match(/(.+?) (\/.+\/)/)
          expr, kana, eigo_raw = m[1], m[1], m[2]
        else
          next
        end
        eigo, prio =
          Dict.edict_clean_eigo(eigo_raw),
          eigo_raw.include?('(P)')
        entry = Entry.new(expr, kana, eigo, prio)
        entries << entry
        pr.tick
      end
    end

    print "  writing .sqlite... "
    @@db.execute "BEGIN"
    Progress.new(entries.size) do |pr|
      entries.each do |entry|
        expr, kana, eigo, prio =
          entry.expr,
          entry.kana,
          entry.eigo.gsub("'","''"),
          entry.priority? ? 1:0
        @@db.execute "INSERT OR IGNORE INTO edict VALUES ('#{expr}', '#{kana}', '#{eigo}', #{prio})"
        pr.tick
      end
    end
    @@db.execute "END"

    @@db.close #TODO no @@
    FileUtils.mv "#{$RES_DIR}/.sqlite/dict.sqlite.tmp", "#{$RES_DIR}/.sqlite/dict.sqlite"
  end

  def Dict.load!
    puts "Loading dictionaries... "
    if !File.exist? "#{$RES_DIR}/.sqlite/dict.sqlite"
      Dict.create_sqlite
    end
    @@db = SQLite3::Database.new("#{$RES_DIR}/.sqlite/dict.sqlite", {flags: SQLite3::Constants::Open::READONLY})
  end

private

  # kanjidic helpers

  def Dict.kanjidic_eigo_from_line(line)
    line.scan(/\{.*?\}/).map {|x| x[1..-2]}
  end

  def Dict.kanjidic_yomi_from_line(line)
    yarr = []
    line.split(' ').each do |part|
      yarr << part if part.chars.any? {|x| x.kana?}
      break if part[0] == 'T' # up to nanori
    end
    yarr
  end

  def Dict.kanjidic_nanori_from_line(line)
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

  def Dict.kanjidic_heisig_from_line(line)
    m = line.match(/\sL(\d{1,4})\s/)
    if m
      m[1].to_i
    else
      nil
    end
  end

  def Dict.kanjidic_stroke_count_from_line(line)
    m = line.match(/\sS(\d{1,2})\s/)
    if m
      m[1].to_i
    else
      nil
    end
  end

  # edict helpers

  def Dict.edict_clean_eigo(eigo_raw)
    e = eigo_raw.dup
    e.scan(/\(.+?\)/).each do |part|
      if part[1..-2].split(',').all? {|p| @@markers.include? p}
        e.sub!(part, '')
        e.sub!('  ', ' ')
      end
    end
    e.split('/').delete_if {|x| x.empty?}.map {|x| x[0..0]==' ' ? x[1..-1] : x}.join('; ')
  end

#-----

public

  class Entry

    attr_reader :expr, :kana, :eigo, :priority
    attr_writer :fake
    attr_accessor :alts, :seki

    def initialize(expr, kana, eigo, prio)
      @expr, @kana, @eigo, @priority = expr, kana, eigo, prio
      @fake, @alts, @seki = false, nil, nil
      [@expr, @kana, @eigo].each {|v| v.freeze}
    end

    def priority?#TODO rename
      @priority
    end

    #TODO review
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
