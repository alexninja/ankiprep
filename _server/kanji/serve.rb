require 'misc/template'

$RIKAICHAN_TXT = "D:/_rikaichan.txt"

module Kanji

  def self.serve(url, s)

    @data ||= {}
    @data.delete_if {|k,v| (Time.now - v.time) > 10}

    if m = url.match(/^kanji\/([0-9a-fA-F]{4})$/)
      utf16 = m[1]
      s.print "HTTP/1.1 200/OK\r\n"
      s.print "Content-type: text/html\r\n\r\n"
      s.print $T['kanji/redirect.html'].with(UTF16: utf16)

    elsif m = url.match(/^kanji\/(set|copy)\/([0-9a-fA-F]{4})\/(\d+)\/(\d+)\/(.+)$/)
      op, utf16, cur, tot, chunk = m[1], m[2], m[3], m[4], m[5]
      s.print "HTTP/1.1 200/OK\r\n"
      s.print "Content-type: text/html\r\n\r\n"
      @data[utf16] ||= Struct.new(:time, :chunks).new(Time.now, [nil] * tot.to_i)
#      if @data[utf16].chunks[cur.to_i - 1] != nil
#        puts "chunk aborted! (chunk #{cur}/#{tot} was already present)"
#        @data.delete utf16
#        return
#      end
      @data[utf16].chunks[cur.to_i - 1] = chunk
      @data[utf16].time = Time.now
      puts "[got chunk #{cur}/#{tot} for #{utf16}]"
      if op == "copy" && @data[utf16].chunks.all? {|c| c != nil}
        if @last_copy_time && (Time.now - @last_copy_time) < 0.5
          puts "chunk aborted! (within 0.5s of last; prevent double click)"
          @data.delete utf16
          return
        end
        data = @data[utf16].chunks.join
        result = `copytocb.exe #{data}`
        puts result
        s.print result
        puts "running `AutoIt3.exe ankipaste.au3`"
        puts `AutoIt3.exe ankipaste.au3`
        @last_copy_time = Time.now
        @data.delete utf16
      end

    elsif m = url.match(/^kanji\/show\/([0-9a-fA-F]{4})$/)
      utf16 = m[1]
      s.print "HTTP/1.1 200/OK\r\n"
      s.print "Content-type: text/html\r\n\r\n"
      if @data.has_key?(utf16) && @data[utf16].chunks.all? {|c| c != nil}
        # data available, load the two-frame html
        s.print $T['kanji/report.html'].with(UTF16: utf16)
      else
        # keep redirecting until we have data
        s.print $T['kanji/redirect.html'].with(UTF16: utf16)
      end

    elsif m = url.match(/^kanji\/show\/(flashcard|wordlist)\/(.+)\.(.+)$/)
      dir, file, ext = m[1], m[2], m[3]
      path = "../_ankiprep/__OUT__/kanji/#{dir}/#{file}.#{ext}"
      if ext == "html"
        return unless m = file.match(/^([kw])([0-9a-fA-F]{4})$/)
        prefix, utf16 = m[1], m[2]
        html = File.read(path, mode:'r:UTF-8')
        if dir == "flashcard" && prefix == "k"
          data_override = CGI.unescape( @data[utf16].chunks.join )
          html.sub!("var _data_override = null", "var _data_override = #{data_override}")
          @data.delete utf16
        end
        s.print "HTTP/1.1 200/OK\r\n"
        s.print "Content-type: text/html\r\n\r\n"
        s.print html
      elsif ext == "js"
        s.print "HTTP/1.1 200/OK\r\n"
        s.print "Content-type: text/javascript\r\n\r\n"
        s.print File.read(path, mode:'r:UTF-8')
      elsif ext == "css"
        s.print "HTTP/1.1 200/OK\r\n"
        s.print "Content-type: text/css\r\n\r\n"
        s.print File.read(path, mode:'r:UTF-8')
      elsif ext == "png" || ext == "gif"
        path = "#{$GIFDIR}/#{file}.#{ext}" if ext == "gif"
        if File.exist? path
          s.print "HTTP/1.1 200/OK\r\n"
          s.print "Content-Type: image/#{ext}\r\n"
          s.print "Accept-Ranges: bytes\r\n"
          s.print "Content-Length: #{File.size(path)}\r\n\r\n"
          s.print open(path,'rb') {|io| io.read}
        else
          s.print "HTTP/1.1 404 Not Found\r\n"
        end
      end

    elsif m = url.match(/^kanji\/heisig\/(\d+\.png)$/)
      path = "#{$DICT_DIR+'/heisig'}/#{m[1]}"
      s.print "HTTP/1.1 200/OK\r\n"
      s.print "Content-Type: image/png\r\n"
      s.print "Accept-Ranges: bytes\r\n"
      s.print "Content-Length: #{File.size(path)}\r\n\r\n"
      s.print open(path,'rb') {|io| io.read}

    elsif m = url.match(/^kanji\/vocabsave\/1\/1\/(.+)$/)
      # FIXME: server_send_chunked() is an atrocious hack, why didn't it occur to me to use POST???
      # I'm counting on always sending one 512-byte chunk which "ought to be enough for everyone"...
      if m[1] != @last_vocab_save
        expr, kana, eigo = CGI.unescape(m[1]).split("\t")
        str = "#{expr}\t#{kana}\t#{eigo}"
        puts "Saving to #{$RIKAICHAN_TXT}: #{str}"
        File.open($RIKAICHAN_TXT, 'a') {|f| f.puts str}
        @last_vocab_save = m[1]
        Audio.ding()
      else
        # my accept loop seems to be wrong, look into it sometime
        puts "unexplained repeated request ignored..."
      end

    end
  end

end # module
