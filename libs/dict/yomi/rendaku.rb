require_relative 'readpairs'

module Yomi

  @rendakuh = Hash.new {|h,k| h[k] = []}
  @rendakut = Hash.new {|h,k| h[k] = []}

  readpairs('../libs/dict/yomi/rendakuh.txt').each {|p| @rendakuh[p[0]] << p[1]}
  readpairs('../libs/dict/yomi/rendakut.txt').each {|p| @rendakut[p[0]] << p[1]}

  def Yomi.rendakuh(frag)
    head = frag[0]
    tail = frag[1..-1]
    @rendakuh[head].map {|h| h+tail}
  end

  def Yomi.rendakut(frag)
    return [] if frag.length == 1 #TODO see if needed
    tail = frag[-1]
    head = frag[0..-2]
    @rendakut[tail].map {|t| head+t}
  end

end # module
