# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

$OUTDIR = '__OUT__'


start = Time.now

require 'fileutils'
require 'misc/time'
require_relative 'vocab/main'

FileUtils.mkdir_p $OUTDIR

Vocab.makeall

puts "all done in " + format_time(Time.now - start)
