# encoding: UTF-8
$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

$SRCDIR = "__!sources!__"

require 'misc/utf8'
require 'misc/progress'


$kanji = []


print "extracting kanji from ankiexp.txt... "
Progress.new do
  count = 0
  Utf8.readlines($SRCDIR+"/ankiexp.txt").each do |line|
    if m = line.match(/.+\t(.+)$/)
      count += 1
      $kanji << m[1]
    end
  end
  print "(#{count} found) "
end


print "extracting Heisig names from heisigwords.html... "
Progress.new do
  count = 0
  Utf8.readlines($SRCDIR+"/heisigwords.html","EUC-JP").each do |line|
    if m = line.match(/<tr><td>(.+)<\/td><td>(.+)<\/td><\/tr>/)
      count += 1
      k, h = m[1], m[2]
    end
  end  
  print "(#{count} found) "
end
