class String
  def safe_sub(s1, s2)
    if beg = self.index(s1)
      ret = self.dup
      ret[beg,s1.size] = s2
      ret
    else
      self
    end
  end
end

class String
  def escape
    self.split('"').join('\\\\\"').split("'").join("\\'")
  end
  def unescape
    self.split('\\\\\"').join('"').split("\\'").join("'")
  end
end
