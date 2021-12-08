class String

  def utf16_code
    self.encode('utf-16le').chars.map do |c|
      b0, b1 = c.bytes.to_a
      ((b1 << 8) + b0).to_s(16).rjust(4,'0')
    end.
      join
  end

  def charfrom_utf16
    raise "expected 4-byte string" unless self.size == 4
    [self].pack("H*").force_encoding('utf-16be').encode('UTF-8')
  end

end
