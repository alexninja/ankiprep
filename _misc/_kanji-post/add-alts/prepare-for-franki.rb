# encoding: UTF-8
$: << File.expand_path(File.dirname(__FILE__) + '/../../libs')

# - add alternate spellings (Edict::Entry::alts) to entries
# - as a bonus, compare the entries against the current edict
# - as a bonus, change use:1 and use:0 to use:true/false, and eliminate spaces in yomi & nanori enumerations (see notes.txt)

require 'set'
require 'edict'
require 'kanjidic'
require 'kana'
require 'etc/add_alts'
require 'etc/string_extras'
require 'misc/utf8'
require 'misc/template'
require 'misc/progress'

$log = File.open('log.txt','w')
$warnings = 0
$t = T.new('etc')

kanji = Set.new
text, html = [], []

lines = Utf8.readlines('kanji.anki-exported.txt')

print "Converting... "
Progress.new(lines.size) do |pr|

  lines.each do |line|
    line_cln = line.gsub('&quot;', '"')

    m = line_cln.match(/kanji:\"(.)\".+\t(.)$/)
    raise "bad line #{line_cln}" unless m
    k_js, k = m[1], m[2]
    raise "kanji mismatch: #{k_js} != #{k}" if k_js != k
    raise "duplicate #{k}" if kanji.include? k
    kanji << k

    t, h = add_alts(line_cln)

    text << line.split("\t").first + "\t" + t
    html << h

    pr.tick
  end

end

# dump

File.open('kanji.anki-corrected.txt','w') do |f|
  f.write text.join("\n")
end

File.open('report.html','w') do |f|
  f.write $t['report.html'].safe_sub('$BODY', html.join("\n"))
end

if $warnings > 0
  puts "#{$warnings} warnings! see log.txt!"
end
