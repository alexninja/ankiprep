@echo off
rem used for quickly testing changes to flashcard html/css/js
rem generates report files, then displays a (dummy) report page in firefox

cd t

ruby gen.rb

copy __gen\flashcard.css                __testpage\kanji-flashcards
copy __gen\flashcard.js                 __testpage\kanji-flashcards
copy __gen\k4f1a.html                   __testpage\kanji-flashcards
copy ..\png\*.png                       __testpage\kanji-flashcards

copy ..\..\kanji-wordlist\wordlist.css  __testpage\kanji-wordlists

start firefox                           __testpage\testpage.html
