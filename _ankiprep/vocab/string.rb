
class String

  def highlight(substr, cond = true)
    if cond
      self.gsub(substr, "<span class='hl'>" + substr + "</span>")
    else
      self
    end
  end

#  def nobr
#    "<nobr>" + self + "</nobr>"
#  end

end

