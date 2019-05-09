require '../../../libs/misc/template'
require 'fileutils'

$GIFDIR = 'D:/Japanese/_dict/gif'
$HEISIG_DIR = "D:/Japanese/_dict/heisig"

Dir.mkdir "__OUT__" unless File.exist? "__OUT__"
Dir.mkdir "__OUT__/kanji-flashcards" unless File.exist? "__OUT__/kanji-flashcards"

# make report flashcard files

File.open("__OUT__/kanji-flashcards/k4f1a.html", 'w') do |f|
  f.write $T['../flashcard.html'].apply_ifdef('REPORT').with(
    UTF16: "4f1a",
    DATA: File.read('data.json', mode:'r:UTF-8'),
    WORD_COUNTS: File.read('word_counts.json', mode:'r:UTF-8'),
    GIFDIR: $GIFDIR,
    HEISIG_DIR: $HEISIG_DIR,
    HEISIG_PNG: '',
    HEISIG_IMG_TAG: ''
  ).check
end

File.open("__OUT__/flashcard.js", 'w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('REPORT')
end

File.open("__OUT__/flashcard.css", 'w') do |f|
  f.write $T['../flashcard.css'].apply_ifdef('REPORT')
end


# make anki .js files

# answer

File.open('__OUT__/answer.js','w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('ANKI','ANSWER').with(
    HTML: $T['../flashcard.html'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ',''),
    CSS: $T['../flashcard.css'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,'')
  ).check
end

# recognition

File.open('__OUT__/recog.js','w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('ANKI','RECOG').with(
    HTML: $T['../flashcard.html'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ',''),
    CSS: $T['../flashcard.css'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,'')
  ).check
end

# production

File.open('__OUT__/prod.js','w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('ANKI','PROD').with(
    HTML: $T['../flashcard.html'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ',''),
    CSS: $T['../flashcard.css'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,'')
  ).check
end

