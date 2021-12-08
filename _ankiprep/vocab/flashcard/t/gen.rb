require 'FileUtils'
require '../../../../libs/misc/template'

FileUtils.mkdir_p "__OUT__"

# make testpage flashcard files

File.open("__OUT__/flashcard.html", 'w') do |f|
  f.write $T['../flashcard.html'].apply_ifdef('TESTPAGE').with(
    DATA: File.read('data.json', mode:'r:UTF-8').split("\t").first
  ).check
end

File.open("__OUT__/flashcard.js", 'w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('TESTPAGE')
end

File.open("__OUT__/flashcard.css", 'w') do |f|
  f.write $T['../flashcard.css'].apply_ifdef('TESTPAGE')
end


# make anki .js files

File.open('__OUT__/recog.js','w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('ANKI','RECOG').with(
    HTML: $T['../flashcard.html'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ',''),
    CSS: $T['../flashcard.css'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,''),
  ).check
end

File.open('__OUT__/prod.js','w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('ANKI','PROD').with(
    HTML: $T['../flashcard.html'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ',''),
    CSS: $T['../flashcard.css'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,''),
  ).check
end

File.open('__OUT__/answer.js','w') do |f|
  f.write $T['../flashcard.js'].apply_ifdef('ANKI','ANSWER').with(
    HTML: $T['../flashcard.html'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ',''),
    CSS: $T['../flashcard.css'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,''),
  ).check
end


# make anki snippets

File.open('__OUT__/recog.html','w') do |f|
  f.write $T['../anki-snippet.html'].with(
    JS_EXT_GARBLED: "<script src='recog.js'></script>".reverse
  ).check.gsub("\n",'').gsub('  ','')
end

File.open('__OUT__/prod.html','w') do |f|
  f.write $T['../anki-snippet.html'].with(
    JS_EXT_GARBLED: "<script src='prod.js'></script>".reverse
  ).check.gsub("\n",'').gsub('  ','')
end

File.open('__OUT__/answer.html','w') do |f|
  f.write $T['../anki-snippet.html'].with(
    JS_EXT_GARBLED: "<script src='answer.js'></script>".reverse
  ).check.gsub("\n",'').gsub('  ','')
end

