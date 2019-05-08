class String

  def urlify(href, frame)
    "<a href=\"#{href}\" target=\"#{frame}\">#{self}</a>"
  end

end
