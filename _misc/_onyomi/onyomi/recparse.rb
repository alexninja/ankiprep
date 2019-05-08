require 'onyomi/rendaku'

def recparse(expr, kana, arr, &block)  #expr and kana are already .moji

  #puts "#{expr.join} | #{kana.join}<br>"

  if expr.empty?
    if kana.empty?
      block.call(arr)
    elsif kana.size==1 and arr[-1] and arr[-1].frag.hir?
      block.call(arr << Seki.new(kana[0],kana[0],''))
    end
    return
  end

  moji = expr[0]

  yomi_all = if moji.kanji?
    Kanji.yomi(moji).map {|y| y.split('.')[0]}.uniq
  else
    [moji]
  end

  yomi_all.each do |yomi|
    ylen = yomi.moji.length
    frag = kana[0...ylen].join

    yomivar = [yomi]

    if moji.kanji?
      yomivar += rendakuh(yomi) unless arr.size==0 #first moji
      yomivar += rendakut(yomi) unless expr.size==1 #last moji
      yomivar.uniq!
    end

    if yomivar.any? {|v| v.to_hir == frag.to_hir}
      arr << Seki.new(yomi,frag,moji)
      recparse(expr[1..-1], kana[ylen..-1], arr, &block)
      arr.delete_at(-1)
    end
  end

end
