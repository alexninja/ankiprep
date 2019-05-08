module Utf8

  BOM          = "\xEF\xBB\xBF".force_encoding("UTF-8")
  Comma        = "\xE3\x80\x81".force_encoding("UTF-8")
  Space        = "\xE3\x80\x80".force_encoding("UTF-8")
  BracketOpen  = "\xE3\x80\x8C".force_encoding("UTF-8")
  BracketClose = "\xE3\x80\x8D".force_encoding("UTF-8")
  Rarrow       = "\xE2\x86\x92".force_encoding("UTF-8")
  Ellipsis     = "\xE2\x80\xA6".force_encoding("UTF-8")
  Kurikaeshi   = "\xE3\x80\x85".force_encoding("UTF-8")

  def Utf8.from_utf16code(i)
    s = String.new('xx')
    s.setbyte(0, i & 0xff)
    s.setbyte(1, i >> 8)
    s.force_encoding('utf-16le')
    s.encode('utf-8')
  end

  def Utf8.readlines(file, src_encoding='UTF-8')
    mode = if src_encoding == 'UTF-8'
      { mode: 'r:UTF-8' }
    else
      { mode: "r:#{src_encoding}:UTF-8" }
    end
    lines = File.readlines(file, mode).map {|line| line.chomp}
    if (src_encoding.upcase == 'UTF-8' && !lines.empty? && !lines[0].empty? && lines[0][0] == Utf8::BOM)
      lines[0].replace(lines[0][1..-1])
    end
    lines
  end

end
