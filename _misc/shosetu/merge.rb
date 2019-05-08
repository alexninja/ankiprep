$: << File.expand_path(File.dirname(__FILE__) + '/../libs')
$KCODE = 'U'

require 'misc/chomp_utf8'

File.open('merged.txt','w') do |f|
  (1..98).each do |i|
    f.puts "\n\n\n\n=== #{i} ===\n\n\n\n"
    File.readlines("@no=#{i}").each do |line|
      f.puts line.chomp_utf8
    end
  end
end
