# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

$OUTDIR = '__OUT__'


require_relative 'vocab/main'
require_relative 'kanji/main'
require 'misc/time'


start = Time.now

Vocab.makeall
Kanji.makeall

puts "all done in " + format_time(Time.now - start)
