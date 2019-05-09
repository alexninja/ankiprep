@echo off
rem used for quickly testing changes to flashcard html/css/js
rem generates report files, then displays a (dummy) report page in firefox

cd t

ruby gen.rb

if not exist "__OUT__"                  mkdir __OUT__
if not exist "__OUT__\kanji"            mkdir __OUT__\kanji
if not exist "__OUT__\kanji\flashcards" mkdir __OUT__\kanji\flashcards
if not exist "__OUT__\kanji\wordlists"  mkdir __OUT__\kanji\wordlists

copy testpage.html                      __OUT__

copy __OUT__\flashcard.css              __OUT__\kanji\flashcards
copy __OUT__\flashcard.js               __OUT__\kanji\flashcards
copy __OUT__\k4f1a.html                 __OUT__\kanji\flashcards
copy ..\png\*.png                       __OUT__\kanji\flashcards

copy w4f1a.html                         __OUT__\kanji\wordlists
copy ..\..\kanji-wordlist\wordlist.css  __OUT__\kanji\wordlists


start firefox                           __OUT__\testpage.html
