require 'kana'
require_relative 'readpairs'

module Yomi

  @rendakuh = Hash.new {|h,k| h[k] = []}
  @rendakut = Hash.new {|h,k| h[k] = []}

  readpairs('../libs/yomi/rendakuh.txt').each {|p| @rendakuh[p[0]] << p[1]}
  readpairs('../libs/yomi/rendakut.txt').each {|p| @rendakut[p[0]] << p[1]}

  def Yomi.rendaku(yomi)
    ([yomi] + rendakuh(yomi) + rendakut(yomi)).uniq
  end

  def Yomi.rendakuh(yomi)
    head = yomi[0]
    rest = yomi[1..-1]
    @rendakuh[head.to_hir].map {|v| v+rest}
  end

  def Yomi.rendakut(yomi)
    tail = yomi[-1]
    strt = yomi[0..-2]
    @rendakut[tail.to_hir].map {|v| strt+v}
  end

end # module
