class String

  # similar to utf16.rb, except order of bytes reversed

  def sjis_code
    self.encode('Shift_JIS').chars.map do |c|
      b0, b1 = c.bytes.to_a
      ((b0 << 8) + b1).to_s(16).rjust(4,'0')
    end.
      join
  end

end
