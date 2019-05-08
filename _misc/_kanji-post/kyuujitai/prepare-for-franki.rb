# encoding: UTF-8
$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

# - remove `havepic` keys from json
# - clean up any entries with quotes around key names
# - add `kjt` keys to kyuujitai kanji, referencing their modern counterparts

require 'set'
require 'misc/utf8'
require 'misc/utf16'

# read in kyuujitai data from Asahi

kjt = Hash.new {|h,k| h[k] = ''}

File.read('__sources__/old_chara.html', mode:'r:Shift_JIS:UTF-8')
    .scan(/\s+<td class="ch">(.+)<\/td>\n\s+<td class="ch">(.+)<\/td>/)
    .each do |new,old|
      old = old[3..6].charfrom_utf16 if old.match(/&#x.{4};/)
      kjt[old] << new
    end

# make changes to Anki data

kanji = Set.new

out = Utf8.readlines('../kanji.anki-exported.txt').map do |line|

  m = line.match(/(kanji|\"kanji\"):\"(.)\".+\t(.)$/)
  raise "bad line #{line}" unless m
  k, tag = m[2], m[3]
  raise "duplicate #{k}" if kanji.include? k
  raise "kanji/tag mismatch: #{k}" if k != tag
  kanji << k

  line = line[0..-3] # get rid of trailing tab+kanji tag

  line_new = line.sub('"use":'         , 'use:')
                 .sub('"freq":'        , 'freq:')
                 .sub('"words":'       , 'words:')
                 .sub('"yomi":'        , 'yomi:')
                 .sub('"nanori":'      , 'nanori:')
                 .sub('"eigo":'        , 'eigo:')
                 .sub('"utf16":'       , 'utf16:')
                 .sub('"kanji":'       , 'kanji:')
                 .sub('"havepic":'     , 'havepic:')  # correct any double-quoted keys
                 .sub(',havepic:true'  , '')
                 .sub(',havepic:false' , '')          # and lose the havepic key altogether

  if kjt.has_key? k
    line_new = line_new[0..-2] + ',kjt:"' + kjt[k] + '"}'
  end

  line + "\t" + line_new + "\t" + k

end

# dump

File.open('kanji.anki-corrected.txt','w') do |f|
  out.each do |line|
    f.puts line
  end
end


