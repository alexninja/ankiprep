require_relative 'recparse'


module Yomi

  def Yomi.parse(entry)
    if entry.expr.chars.any? {|x| x.kanji?}
      recparse(entry.expr.chars.to_a, entry.kana.chars.to_a, []) do |arr|
        return arr
      end
    end
    return []
  end

end
