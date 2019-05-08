# encoding: utf-8

$: << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'misc/chomp_utf8'
require 'misc/moji'

p Encoding.default_external

p "lol".encoding





File.readlines('words.txt').each do |line|
#File.readlines('words.txt',mode:"rb:UTF-8").each do |line|
#open('words.txt','r:UTF-8') do |f|

#f.each do |line|
p line.encoding.name

line.chomp!
#  line.each_byte {|x| a << x.to_s(16)}
#p line.encoding
#p line.size
p line.chars.select {|x| x}
  a = []; line.chars.each {|c| a<<c}; p a
  a = []; line.reverse.chars.each {|c| a<<c}; p a
end

#end