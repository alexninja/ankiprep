# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

$RES_DIR = '../_res'

$OUTDIR = '__OUT__'

$ANKIDIR = '/Japanese/_anki/_current'


start = Time.now

require 'fileutils'
require 'etc/time'
require 'vocab/main'

FileUtils.mkdir_p $OUTDIR

Vocab.makeall

puts "all done in " + format_time(Time.now - start)
