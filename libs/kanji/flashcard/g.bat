@echo off
rem after making (and being happy with) changes to flashcard html/css/js
rem run this script to see these changes in Anki and __OUT__

cd t

ruby gen.rb

copy /Y __OUT__\answer.js      D:\Japanese\_anki\_current\kanji.media
copy /Y __OUT__\prod.js        D:\Japanese\_anki\_current\kanji.media
copy /Y __OUT__\recog.js       D:\Japanese\_anki\_current\kanji.media

copy /Y __OUT__\kanji\flashcard\flashcard.css  ..\..\..\__OUT__\kanji\flashcard
copy /Y __OUT__\kanji\flashcard\flashcard.js   ..\..\..\__OUT__\kanji\flashcard
