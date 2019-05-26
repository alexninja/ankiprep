require 'FileUtils'
require '../../../../libs/misc/template'


FileUtils.mkdir_p "__OUT__/kanji/flashcard"
FileUtils.mkdir_p "__OUT__/kanji/wordlist"


# make report flashcard files

FileUtils.cp_r "k4f1a.html", "__OUT__/kanji/flashcard/k4f1a.html", remove_destination: true

File.open("__OUT__/kanji/flashcard/flashcard.js", 'w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('REPORT')
end

File.open("__OUT__/kanji/flashcard/flashcard.css", 'w') do |f|
  f.write $T['../flashcard.css'].apply_ifdef('REPORT')
end


# make anki files

File.open('__OUT__/answer.js','w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('ANKI','ANSWER').with(
    HTML: $T['../flashcard.html'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ',''),
    CSS: $T['../flashcard.css'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,'')
  ).check
end

File.open('__OUT__/recog.js','w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('ANKI','RECOG').with(
    HTML: $T['../flashcard.html'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ',''),
    CSS: $T['../flashcard.css'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,'')
  ).check
end

File.open('__OUT__/prod.js','w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('ANKI','PROD').with(
    HTML: $T['../flashcard.html'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ',''),
    CSS: $T['../flashcard.css'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,'')
  ).check
end

