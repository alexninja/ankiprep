@echo off
rem after making (and being happy with) changes to flashcard html/css/js
rem run this script to see these changes in Anki and __report__

cd t

ruby gen.rb

copy /Y __gen\answer.js      D:\Japanese\_anki\_current\kanji.media
copy /Y __gen\prod.js        D:\Japanese\_anki\_current\kanji.media
copy /Y __gen\recog.js       D:\Japanese\_anki\_current\kanji.media

copy /Y __gen\flashcard.css  ..\..\__report__\kanji-flashcards
copy /Y __gen\flashcard.js   ..\..\__report__\kanji-flashcards
