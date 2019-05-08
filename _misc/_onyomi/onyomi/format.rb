require 'misc/moji'
require 'misc/utf8'
require 'kana'

@@html = Hash.new
Dir['onyomi/html/*.html'].each do |f|
  @@html[f.split('/').last.split('.')[0]] = File.read(f).freeze
end


def format_table(word, arr)

  comment = if arr.empty?
    @@html['comment'].sub('$TXT', 'no onyomi, could not parse')
  elsif arr.all? {|x| not x.yomi.kat?}
    @@html['comment'].sub('$TXT', 'no onyomi')
  else
    ''
  end

  td_yomi = arr.map do |x|
    kat = x.yomi.kat?
    @@html['td-yomi'].sub('$CLASS', kat ? 'yomi':'yomi-faded').sub('$YOMI', x.yomi)
  end.
    join("\n")

  td_frag = arr.map do |x|
    kat = x.yomi.kat?
    @@html['td-frag'].sub('$CLASS', kat ? 'frag':'frag-faded').sub('$FRAG', x.frag)
  end.
    join("\n")

  td_moji = arr.map do |x|
    kat = x.yomi.kat?
    @@html['td-moji'].sub('$CLASS', kat ? 'moji':'moji-faded').sub('$MOJI', x.moji)
  end.
    join("\n")

  @@html['table'].
    sub('$EXPR', word.expr).
    sub('$KANA', word.kana).
    sub('$COMMENT', comment).
    sub('$TD-YOMI', td_yomi).
    sub('$TD-FRAG', td_frag).
    sub('$TD-MOJI', td_moji)
end


def format_shosai(expr)
  @@html['link-shosai'].sub('$EXPR', expr.gsub(Utf8::Space,'|'))
end

def format_html(body)
  @@html['html'].sub('$BODY', body)
end
