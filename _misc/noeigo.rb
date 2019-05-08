$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

$KCODE = 'U'

require 'edict'
require 'misc/chomp_utf8'

lines = File.readlines('ramen.fixed.txt')

f = File.open('ramen.noeigo.txt','w')

lines.each_with_index do |line,i|

  line.chomp_utf8!
  line.sub!('<br><br>',"\t")
  line.sub!('<br />',"\t")

  expr, eigo, kana =
    if m = line.match(/(.*?)\t(.*)\t(.*)/)
      [m[1], m[2], m[3]]
    else
      [line, nil, nil]
    end

  if Edict.contains? expr
    f.puts expr
  elsif kana
    f.puts "#{expr}\t#{kana}"
  else
    f.puts "[#{i}] \"#{expr}\"not in edict and no kana to fall back on"
    raise 'whoa'
  end

end
