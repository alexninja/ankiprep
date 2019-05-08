# for mass extraction of words from a body of text.
#
# expects files:
#   mecabinput.txt: original body of text (or supply as command line argument)
#   ankiexp.txt: raw list of "cards" exported from anki - optional
#
# operation:
# - calls mecab.exe on the input file (e.g. mecabinput.txt) to extract words
# - skips words not containing any kanji
# - creates two files:
#   mecabwords.html: original body of text with interesting words highlighted:
#     * if word already exists in ankiexp.txt, highlighted green
#     * if word already encountered in this body of text, highlighted light purple
#     * if new word, highlighted purple, with a superscript line number of its location in mecabwords.txt
#   mecabwords.txt: list of new (purple) words
#
# after running, open mecabwords.txt in an editor and manually eliminate unwanted entries by prefixing with a #
# while referencing mecabwords.html when needed
#
# then run mecabwords-post.rb to clean up mecabwords.txt
# this will create mecabwords-ankiprep.txt, which can be fed to ankiprep.rb


$: << File.expand_path(File.dirname(__FILE__) + '/../../libs')

require 'set'
require 'edict'
require 'kanjidic'
require 'misc/utf8'
require 'misc/progress'

infile = if File.exist?('D:/input.txt')
  'D:/input.txt'
else
   ARGV.shift
end

puts "running mecab on #{infile}..."
system('"C:\Program Files (x86)\MeCab\bin\mecab.exe"' + " #{infile} -o mecab.out.tmp")

intext = Utf8::readlines(infile).join('<br>')

exprs = Set.new

print 'sorting it all out... '
mecabwords = []
lines = Utf8::readlines('mecab.out.tmp')
Progress.new(lines.size) do |pr|
  lines.each do |line|
    pr.tick
    m = line.match(/(.*?)\t.*?,.*?,.*?,.*?,.*?,.*?,(.*?),(.*?),.*?/)
    next unless m
    rawexpr, expr, mecabkana = m[1], m[2], m[3]
    next unless expr.chars.any? {|x| x.kanji?}
    next if exprs.include? expr

    if Edict.contains? expr
      entries = Edict.lookup_expr(expr)
      kana = entries.map {|e| e.kana}.uniq.join(',')
      eigoc = entries.map {|e| e.eigoc}.uniq.join(' | ')
      mecabwords << "#{expr}\t#{kana}\t#{eigoc}"
    else
      mecabwords << "#{expr}\t#{mecabkana}\t**NOT IN EDICT**"
    end
    exprs << expr

  end
end

puts "writing #{mecabwords.size} entries to D:\\rikaichan.txt..."
File.open('D:\rikaichan.txt','w') do |f|
  f.write Utf8::BOM
  mecabwords.each {|line| f.puts line}
end

File.delete 'mecab.out.tmp'
puts "Done. Now run vocab-and-kanji.rb or vocab-only.rb"
