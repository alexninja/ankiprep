require '../../libs/misc/template'

Dir.mkdir "__test" unless File.exist? "__test"
Dir.mkdir "__anki" unless File.exist? "__anki"

# make testpage flashcard files

File.open("__test/flashcard.html", 'w') do |f|
  f.write T('flashcard.html').apply_ifdef('TESTPAGE').with(
    DATA: File.read('data.json', mode:'r:UTF-8').split("\t").first
  ).check
end

File.open("__test/flashcard.js", 'w') do |f|
  f.write T('flashcard.js').apply_ifdef('TESTPAGE')
end

File.open("__test/flashcard.css", 'w') do |f|
  f.write T('flashcard.css').apply_ifdef('TESTPAGE')
end


# make anki .js files

File.open('__anki/question.js','w') do |f|
  f.write T('flashcard.js').apply_ifdef('ANKI','QUESTION').with(
    HTML: T('flashcard.html').apply_ifdef('ANKI','QUESTION').check.gsub("\n",'').gsub('  ',''),
    CSS: T('flashcard.css').apply_ifdef('ANKI','QUESTION').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,''),
  ).check
end

File.open('__anki/answer.js','w') do |f|
  f.write T('flashcard.js').apply_ifdef('ANKI','ANSWER').with(
    HTML: T('flashcard.html').apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ',''),
    CSS: T('flashcard.css').apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ','').gsub('  ','').gsub(/\/\*.*?\*\//,''),
  ).check
end


# make anki templates

File.open('__anki/question.html','w') do |f|
  f.write T('anki.html').with(
    JS_EXT_GARBLED: "<script src='question.js'></script>".reverse
  ).check.gsub("\n",'').gsub('  ','')
end

File.open('__anki/answer.html','w') do |f|
  f.write T('anki.html').with(
    JS_EXT_GARBLED: "<script src='answer.js'></script>".reverse
  ).check.gsub("\n",'').gsub('  ','')
end

