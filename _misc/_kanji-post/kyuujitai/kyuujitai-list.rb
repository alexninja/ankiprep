# encoding: UTF-8
$: << File.expand_path(File.dirname(__FILE__) + '/../../libs')

# tentative script to investigate differences between the Asahi and Wikipedia kyuujitai tables.
# A look at the output confirms that Asahi's is the one worth using - it has more kanji, and
# the Wikipedia one has two apparently wrong kanji (岡 for 丘 and 姬 for 姫)

require 'set'
require 'misc/utf16'

kjt_asahi = Hash.new {|h,k| h[k] = ''}
kjt_wiki = Hash.new {|h,k| h[k] = ''}

# asahi

File.read('__sources__/old_chara.html', mode:'r:Shift_JIS:UTF-8')
    .scan(/\s+<td class="ch">(.+)<\/td>\n\s+<td class="ch">(.+)<\/td>/)
    .each do |new,old|
      old = old[3..6].charfrom_utf16 if old.match(/&#x.{4};/)
      kjt_asahi[new] << old
    end

# wikipedia

File.read('__sources__/List_of_joyo_kanji.htm', mode:'r:UTF-8')
    .scan(/<td style="font-size:2em">(.)<\/td>\n<td style="font-size:2em">(.)<\/td>/)
    .each do |new,old|
      kjt_wiki[new] << old
    end

# make report

File.open('report.html','w') do |f|
  f.puts '<head><link type="text/css" rel="stylesheet" href="report.css"></head><body><table>'
  f.puts "<tr><td class='nr'></td><td class='header'>新字体</td><td class='header'>Asahi (#{kjt_asahi.size})</td><td class='header'>Wiki (#{kjt_wiki.size})</td></tr>"
  nr = 1
  (kjt_asahi.keys + kjt_wiki.keys).uniq.each do |k|
    tr_class = ''
    tr_class = 'class="diff"' if kjt_asahi[k].chars.to_a.sort != kjt_wiki[k].chars.to_a.sort
    f.puts "<tr #{tr_class}><td class='nr'>#{nr}</td><td>#{k}</td><td>#{kjt_asahi[k]}</td><td>#{kjt_wiki[k]}</td></tr>"
    nr += 1
  end
  f.puts '</table></body>'
end
