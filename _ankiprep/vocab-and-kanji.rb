# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

$RES_DIR = 'D:/Dev/ankiprep/_res'

$OUTDIR = '__OUT__'

$ANKIDIR = '/Japanese/_anki/_current'


start = Time.now

require 'etc/time'
require 'vocab/main'
require 'kanji/main'

FileUtils.mkdir_p $OUTDIR

Vocab.makeall
Kanji.makeall

puts "all done in " + format_time(Time.now - start)
