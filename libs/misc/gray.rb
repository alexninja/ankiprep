class String

  def gray
    '<span class="gray">' + self + '</span>'
  end

  def gray_if(cond)
    if cond
      self.gray
    else
      self
    end
  end

  def gray_if_tilde
    if self[0] == '~'
      self[1..-1].gray
    else
      self
    end
  end

  def html_gray
    '<font color=#A8A8A8>' + self + '</font>'
  end

  def html_gray_if(cond)
    if cond
      self.html_gray
    else
      self
    end
  end

end
