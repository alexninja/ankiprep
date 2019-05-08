class Word
  attr_reader :expr, :kana

  def initialize(expr, kana, priority=true)
    @expr, @kana, @priority = expr.freeze, kana.freeze, priority.freeze
  end

  def priority?
    @priority
  end

  def to_s
    if kana
      "#{expr}\t#{kana}"
    else
      expr
    end
  end

  # thanks for the mindfuck, "matz"
  def hash
    [expr, kana, priority?].hash
  end

  def eql? other
    [expr, kana, priority?].eql? [other.expr, other.kana, other.priority?]
  end
end
