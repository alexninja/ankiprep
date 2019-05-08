require 'kana'
require 'misc/moji'
require 'onyomi/read_pairs'


$rendakuh = Hash.new {|h,k| h[k] = []}
$rendakut = Hash.new {|h,k| h[k] = []}

read_pairs('onyomi/rendakuh.txt').each {|p| $rendakuh[p[0]] << p[1]}
read_pairs('onyomi/rendakut.txt').each {|p| $rendakut[p[0]] << p[1]}

def rendaku(yomi)
  ([yomi] + rendakuh(yomi) + rendakut(yomi)).uniq
end

def rendakuh(yomi)
  head = yomi.moji[0]
  rest = yomi.moji[1..-1].join
  $rendakuh[head.to_hir].map {|v| v+rest}
end

def rendakut(yomi)
  tail = yomi.moji[-1]
  strt = yomi.moji[0..-2].join
  $rendakut[tail.to_hir].map {|v| strt+v}
end
