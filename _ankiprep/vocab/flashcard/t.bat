@echo off
rem used for quickly testing changes to flashcard html/css/js
rem generates files for a dummy test page and displays it in firefox

cd t

ruby gen.rb

start firefox __OUT__\flashcard.html
