@echo off
rem used for quickly testing changes to flashcard html/css/js
rem generates report files, then displays a (dummy) report page in firefox

cd t

ruby gen.rb

copy testpage.html                      __OUT__

copy ..\png\*.png                       __OUT__\kanji\flashcard

copy w4f1a.html                         __OUT__\kanji\wordlist
copy ..\..\wordlist\wordlist.css        __OUT__\kanji\wordlist

start firefox                           __OUT__\testpage.html
