
module Yomi

  def Yomi.has_yomi?(seki, k, yomi)
    ymain, ytail = yomi.split('.')
    seki.each_with_index do |s,i|
      yomi, frag, moji = s
      next unless (moji == k && yomi == ymain)
      return true if ytail == nil
      return true if ytail == seki[i+1..i+1+ytail.size].map {|s| s[2]}.join
    end
    false
  end

end
