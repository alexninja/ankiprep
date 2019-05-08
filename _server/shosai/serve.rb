require 'misc/utf8'
require 'misc/utf16'
require 'misc/gray'
require 'misc/template'

module Shosai

  @t = T.new('shosai')

  def Shosai.serve(url, s)
    if url.include?('announce?') || url.include?('scrape?') # utorrent
      return
    elsif url.include?('.css')
      path = "shosai/#{url}"
      raise StandardError, "#{path} not found" unless File.exist? path
      s.print "HTTP/1.1 200/OK\r\n"
      s.print "Content-type: text/plain\r\n\r\n"
      s.print File.read(path)
    elsif url.include?('.gif')
      path = "#{$GIFDIR}/#{url}"
      raise StandardError, "#{path} not found" unless File.exist? path
      s.print "HTTP/1.1 200/OK\r\n"
      s.print "Content-Type: image/gif\r\n"
      s.print "Accept-Ranges: bytes\r\n"
      s.print "Content-Length: #{File.size(path)}\r\n\r\n"
      s.print(open(path,'rb') {|io| io.read})
    else
      s.print "HTTP/1.1 200/OK\r\n"
      s.print "Content-type: text/html\r\n\r\n"
      s.print make_html(CGI.unescape(url)).gsub("file:///#{$GIFDIR}/",'')
    end
  end


  # general case is "expr1_synonym1,expr1_synonym2|expr2,~expr2_synonym2_nonpriority"
  def Shosai.make_html(exprs)
    # defer slow-loading libraries
    require 'edict'
    require 'kanjidic'

    body = exprs.split('|').map do |synlist|
      tdrow1, tdrow2 = format_kakijun(synlist)
      dicttbl = format_links(synlist)
      @t['body.html'].
        sub('$TDROW1', tdrow1).
        sub('$TDROW2', tdrow2).
        sub('$DICTTBL', dicttbl)
    end

    @t['html.html'].
      sub('$TITLE', exprs).
      sub('$BODY', body.join('<br>')).
      gsub('$GIFDIR', $GIFDIR)
  end

private

  def Shosai.format_links(synlist)
    synlist.split(',').map do |expr|
      expr = expr[1..-1] if expr[0...1]=='~'
      links = ['link_yahoo.html','link_goo.html','link_sanseido.html','link_kotobank.html','link_alc.html','link_jukuu.html', 'link_googimg.html'].map {|link|
        @t[link].gsub('$EXPR',expr)
      }.join(Utf8::Space)
      kanaeigo = ''
      if Edict.contains? expr
        kanaeigo = Edict.lookup_expr(expr).
          partition {|e| e.priority?}.flatten.
          map {|e|
            audio_link(e) +
            Utf8::Space +
            (e.kana + Utf8::Space + e.eigoc).html_gray_if(!e.priority?)
          }.join("<br>")
      end
      @t['dicttr.html'].sub('$EXPR', expr).sub('$KANAEIGO', kanaeigo).sub('$LINKS', links)
    end.
      join
  end

  def Shosai.format_kakijun(expr)
    tdrow1, tdrow2 = [], []

    expr.chars.to_a.uniq.each do |c|
      next unless c.kanji?

      td1 = @t['td1.html'].dup

      utf16 = c.utf16_code
      have_gif = (File.exist?("#{$GIFDIR}/u#{utf16}-fast.gif") and File.size("#{$GIFDIR}/u#{utf16}-fast.gif") > 0)

      if have_gif
        raise "no matching static gif for u#{utf16}-fast.gif" unless File.exist?("#{$GIFDIR}/u#{utf16}-static.gif")
        td1.sub!('$KANJI', @t['kanji.html'].gsub('$UTF16', utf16))
      else
        td1.sub!('$KANJI', c)
      end

      tdrow1 << td1

      td2 = @t['td2.html'].dup

      if have_gif
        td2.sub!('$ROLLOVER', @t['rollover.html'].gsub('$UTF16', utf16))
      else
        td2.sub!('$ROLLOVER', '')
      end

      yomi = Kanjidic.yomi(c).map do |x|
        parts = x.split('.')
        parts.size == 1 ? x : parts[0] + @t['okurigana.html'].sub('$OKURIGANA', parts[1])
      end.
        join(Utf8::Comma)
      td2.sub!('$YOMI', yomi)

      if Kanjidic.nanori(c).empty?
        td2.sub!('$NANORI_HTML', '')
      else
        td2.sub!('$NANORI_HTML', @t['nanori.html'].sub('$NANORI', Kanjidic.nanori(c).join(Utf8::Comma)))
      end

      eigo = Kanjidic.eigo(c).join(', ')
      td2.sub!('$EIGO', eigo)

      tdrow2 << td2
    end

    [tdrow1.join, tdrow2.join]
  end

  def Shosai.audio_link(e)
    @t['audio.html'].
      gsub('$KANA', e.kana.unpack("H*").first.gsub(/../, '%25\0')).
      gsub('$KANJI', e.expr.unpack("H*").first.gsub(/../, '%25\0'))
  end

end #module
