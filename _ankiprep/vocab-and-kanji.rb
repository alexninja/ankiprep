# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

$DICT_DIR = '../_dict'

$OUTDIR = '__OUT__'

$ANKIDIR = '/Japanese/_anki/_current'


start = Time.now

require 'misc/time'
require_relative 'vocab/main'
require_relative 'kanji/main'

FileUtils.mkdir_p $OUTDIR

Vocab.makeall
Kanji.makeall

puts "all done in " + format_time(Time.now - start)
