require_relative 'rendaku'

# seki list has one entry [yomi, frag, moji] per character in expr
# 結構    けっこう  [["ケチ","けっ","結"],["コウ","こう","構"]]
# 見倣う  みならう  [["み","み","見"],["なら","なら","倣"],["う","う","う"]]


module Yomi

#  @@tailkana = File.read('kanji/tailkana.txt').chomp_utf8.moji

  def Yomi.recparse(expr, kana, arr, &block)  #expr and kana are already .chars

    if expr.empty?
      if kana.empty?
        block.call(arr)
      elsif kana.size==1 && arr[-1] && arr[-1].frag.hir? #&& @@tailkana.include?(kana[0]) - forget for now, only kuchi, kawa, waga, kura fail so we can hand-edit those
        block.call(arr << [kana[0],kana[0],'@'])
      end
      return
    end

    moji = expr[0]

    if moji.kanji?
      yomi_all = Kanjidic.yomi(moji).map do |y|
        y.split('.')[0]
      end.partition do |y|
        y.kat?
      end.map do |ar|
        ar.sort_by {|y| y.size}.reverse
      end.flatten.uniq
      # put exact match, if any, first
      yomi_all.each_with_index do |y,i|
        ylen = y.size
        frag = kana[0...ylen].join
        if y.to_hir == frag.to_hir
          yomi_all[0], yomi_all[i] = yomi_all[i], yomi_all[0]
          break
        end      
      end
    else
      yomi_all = [moji]
    end

    yomi_all.each do |yomi|
      ylen = yomi.size
      frag = kana[0...ylen].join

      yomivar = [yomi]

      if moji.kanji?
        yomivar += rendakuh(yomi) unless arr.size==0 #first char
        yomivar += rendakut(yomi) unless expr.size==1 #last char
        yomivar.uniq!
      end

      if yomivar.any? {|v| v.to_hir == frag.to_hir}
        arr << [yomi,frag,moji]
        if expr[1] == Utf8::Kurikaeshi
          recparse([moji] + expr[2..-1], kana[ylen..-1], arr, &block)
        else
          recparse(expr[1..-1], kana[ylen..-1], arr, &block)
        end
        arr.delete_at(-1)
      end
    end

  end

end # module
