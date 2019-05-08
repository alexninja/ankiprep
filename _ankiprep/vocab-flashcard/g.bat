@echo off
rem after making (and being happy with) changes to flashcard html/css/js
rem run this script to see these changes in Anki

ruby gen.rb

copy /Y __anki\question.js  D:\Japanese\_anki\_current\vocab.media\
copy /Y __anki\answer.js    D:\Japanese\_anki\_current\vocab.media\
