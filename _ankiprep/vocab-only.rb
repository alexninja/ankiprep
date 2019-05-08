# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

require_relative 'vocab/main'

$REPORTDIR = '__OUT__'


Vocab.makeall
