require 'dict/kana'
require 'etc/progress'

module Kanjidic

  def Kanjidic.kanji?(k)
    @k.has_key?(k)
  end

  def Kanjidic.eigo(k)
    return [] unless kanji?(k)
    @k[k].scan(/\{.*?\}/).map {|x| x[1..-2]}
  end

  def Kanjidic.yomi(k)
    return [] unless kanji?(k)
    yarr = []
    @k[k].split(' ').each do |part|
      yarr << part if part.chars.any? {|x| x.kana?}
      break if part[0] == 'T' # up to nanori
    end
    yarr
  end

  def Kanjidic.nanori(k)
    return [] unless kanji?(k)
    retval = []
    past_T = false
    @k[k].split(' ').each do |part|
      if past_T
        retval << part if part.chars.any? {|x| x.kana?}
      else
        past_T = true if part[0] == 'T'
      end
    end
    retval
  end

  def Kanjidic.heisig(k)
    return nil unless kanji?(k)
    m = @k[k].match(/\sL(\d{1,4})\s/)
    if m
      m[1].to_i
    else
      nil
    end
  end

  def Kanjidic.stroke_count(k)
    return nil unless kanji?(k)
    m = @k[k].match(/\sS(\d{1,2})\s/)
    if m
      m[1].to_i
    else
      nil
    end
  end

  def Kanjidic.each_kanji
    @k.each_key {|k| yield k}
  end

  def Kanjidic.size
    @k.size
  end

private

  def Kanjidic.load!
    print "Loading Kanjidic... "

    Progress.new do |pr|
      lines = Utf8.readlines($RES_DIR+"/dict/kanjidic",'euc-jp')
      File.open($RES_DIR+'/dict/kanjidic.utf8','w') {|f| lines.each {|line| f.puts line}}

      @k = Hash.new()
      lines[1..-1].each do |line|
        kanji = line.split(' ')[0]
        raise "duplicate kanji in kanjidic" if @k.has_key?(kanji)
        @k[kanji] = line
      end
    end

    @k.freeze
  end

  load!

end #module


class String
  def kanji?
    Kanjidic.kanji?(self)
  end
end
