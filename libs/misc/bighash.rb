class String
  def bighash
    def pad(s); s = '0'+s while s.size<8; s; end
    pad(self.hash.abs.to_s(16)).upcase + pad(self.reverse.hash.abs.to_s(16)).upcase
  end
end