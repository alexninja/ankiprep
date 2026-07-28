module Yomi

  def Yomi.readpairs(filename)

    Utf8.readlines(filename).map do |line|
      if m = line.match(/(.*)\t(.*)/)
        [m[1], m[2]]
      else
        nil
      end
    end.
      compact
  end

end # module
