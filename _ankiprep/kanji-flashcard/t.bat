@echo off
rem used for quickly testing changes to flashcard html/css/js
rem generates report files, then displays a (dummy) report page in firefox

cd t

ruby gen.rb

if not exist "__gen\kanji-flashcards" mkdir __gen\kanji-flashcards
if not exist "__gen\kanji-wordlists" mkdir __gen\kanji-wordlists

copy __testpage\testpage.html           __gen

copy __gen\flashcard.css                __gen\kanji-flashcards
copy __gen\flashcard.js                 __gen\kanji-flashcards
copy __gen\k4f1a.html                   __gen\kanji-flashcards
copy ..\png\*.png                       __gen\kanji-flashcards

copy __testpage\w4f1a.html              __gen\kanji-wordlists
copy ..\..\kanji-wordlist\wordlist.css  __gen\kanji-wordlists


start firefox                           __gen\testpage.html
