require 'set'
require 'misc/utf8'


module Kana

  @hir = (0x3041..0x3096).map {|i| Utf8.from_utf16code(i)}.freeze
  @kat = (0x30A1..0x30FF).map {|i| Utf8.from_utf16code(i)}.freeze # NB longer than @hir

  def Kana.kana? str
    str.chars.all? {|c| @hir.include?(c) || @kat.include?(c)}
  end

  def Kana.hir? str
    str.chars.all? {|c| @hir.include? c}
  end

  def Kana.kat? str
    str.chars.all? {|c| @kat.include? c}
  end

  def Kana.to_hir str
    str.chars.map do |c|
      if ki = @kat.index(c) # nil if not found
        if ki < @hir.size # katakana beyond 0x30F6 doesn't map to hiragana
          c = @hir[ki]
        end
      end
      c
    end.join
  end

  def Kana.each_kana
    @hir.each {|c| yield c}
    @kat.each {|c| yield c}
  end

end


class String

  def kana?
    Kana.kana? self
  end

  def hir?
    Kana.hir? self
  end

  def kat?
    Kana.kat? self
  end

  def to_hir
    Kana.to_hir self
  end

end
