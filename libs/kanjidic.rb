require 'kana'
require 'misc/progress'

module Kanjidic

  @yomi_cache = Hash.new

  def Kanjidic.kanji?(k)
    @k.has_key?(k)
  end

  def Kanjidic.eigo(k)
    return [] unless kanji?(k)
    @k[k].scan(/\{.*?\}/).map {|x| x[1..-2]}
  end

  def Kanjidic.yomi(k, which = :all)
    return [] unless kanji?(k)
    yarr = @yomi_cache[k] || []
    if yarr.empty?
      @k[k].split(' ').each do |part|
        yarr << part if part.chars.any? {|x| x.kana?}
        break if part[0] == 'T' # up to nanori
      end
      @yomi_cache[k] = yarr
    end
    case which
      when :all then yarr
      when :on then yarr.select {|x| x.kat?}
      when :kun then yarr.delete_if {|x| x.kat?}
      else raise 'bad argument'
    end
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

      filename = $DICT_DIR+"/edict/kanjidic.utf8"

      unless File.exist? filename
        print 'converting... '
        File.open(filename,'w') do |f|
          Utf8.readlines($DICT_DIR+"/edict/kanjidic",'euc-jp').each {|line| f.puts line}
        end
      end

      lines = Utf8.readlines(filename)

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
