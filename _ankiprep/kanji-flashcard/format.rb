require 'json'
require 'misc/template'
require 'misc/jsontrim'
require 'kanjidic'
require 'fileutils'
require_relative '../kanji/stats'

$GIFDIR = 'D:/Japanese/_dict/gif'
$HEISIG_DIR = "D:/Japanese/_dict/heisig"

module Flashcard

  @t = T.new("kanji-flashcard")
  @heisig_list = Dir[$HEISIG_DIR+'/*.png'].map {|f| f.match(/\/(\d{4})\.png/)[1].to_i}.to_set

  def Flashcard.makeall
    print "[Flashcard] generating #{Stats.new_kanji.size} html files... "

    Dir.mkdir $REPORTDIR unless File.exist? $REPORTDIR
    Dir.mkdir $REPORTDIR+'/kanji-flashcards' unless File.exist? $REPORTDIR+'/kanji-flashcards'
    Dir.mkdir $REPORTDIR+'/__anki__' unless File.exist? $REPORTDIR+'/__anki__'
    Dir.mkdir $REPORTDIR+'/__anki__/templates' unless File.exist? $REPORTDIR+'/__anki__/templates'
    Dir.mkdir $REPORTDIR+'/__anki__/media' unless File.exist? $REPORTDIR+'/__anki__/media'

    File.open('D:/kanji.[IMPORT].txt','w') do |ankiimp|
      Progress.new(Stats.new_kanji.size) do |pr|
        Stats.new_kanji.each do |k|
          # create the html flashcard...
          data_json = make_card(k)
          # ... and create a line for importing to kanji.anki (unless it's already there)
          unless Stats.known_kanji? k
            # anki wants \\\" and \' so make it happy
            data_json_escaped = data_json.split('\"').join('\\\\\"').split("'").join("\\'")
            ankiimp.puts "#{data_json_escaped}\t#{k}"
          end
          pr.tick
        end
      end
    end

    make_anki_templates
    FileUtils.copy Dir['kanji-flashcard/png/*.png'], $REPORTDIR+'/kanji-flashcards'
  end

  def Flashcard.make_card(k)
    # creates the kanji's html flashcard in __report__/kanji-flashcards (for display by server.rb),
    # prepopulated with the data json and the word_counts json.
    # also returns the data json for Anki import txt file

    utf16 = k.utf16_code
    yarr = Stats.yarr(k) + [:other]

    on_all, kun_all = Kanjidic.yomi(k).sort_by {|y| Stats.yfreq(k,y)}.reverse.partition {|y| y.kat?}
    kun_all = kun_all.partition {|y| ! y.include?('-')}.flatten

    word_counts = Hash.new
    yarr.each do |y|
      word_counts[y] = [ANK,POM,MON,EDI].map {|src| Stats.words(src, k, y).size}
    end

    data = Hash.new
    yarr.each do |y|
      yb = bracket_yomi(y)
      data[yb] = Hash.new
      data[yb]['use'] = (word_counts[y].inject(0) {|sum,x| sum+=x} > 0)
      if y.class == String && y.kat?
        data[yb]['freq'] = Stats.yfreq(k,y)
      end
      data[yb]['words'] = []
    end
    data['yomi'] = (on_all + kun_all).map {|y| bracket_yomi(y)}
    data['nanori'] = Kanjidic.nanori(k)
    data['eigo'] = Kanjidic.eigo(k).join(', ').sub(", (kokuji)", " (kokuji)")
    data['utf16'] = utf16
    data['kanji'] = k
    kjt = Stats.kjt(k)
    data['kjt'] = kjt unless kjt.empty?

    word_counts_brk = Hash.new
    word_counts.each do |y,arr|
      yb = bracket_yomi(y)
      word_counts_brk[yb] = arr
    end    

    heisig_png, heisig_img_tag = '', ''
    if heisig = Kanjidic.heisig(k)
      if @heisig_list.include? heisig
        heisig_png = "%04d.png" % heisig
        heisig_img_tag = '<p align="center"><img style="border: 2px solid blue" name="heisig_pic"></p>'
      end
    end

    data_json = data.to_json.trim_keys(data)

    File.open($REPORTDIR+"/kanji-flashcards/k#{k.utf16_code}.html", 'w') do |f|
      f.write @t['flashcard.html'].apply_ifdef('REPORT').with(
        UTF16: utf16,
        DATA: data_json,
        WORD_COUNTS: word_counts_brk.to_json,
        GIFDIR: $GIFDIR,
        HEISIG_DIR: $HEISIG_DIR,
        HEISIG_PNG: heisig_png,
        HEISIG_IMG_TAG: heisig_img_tag
      ).check
    end

    File.open($REPORTDIR+"/kanji-flashcards/flashcard.js", 'w') do |f|
      f.write @t['flashcard.js'].apply_ifdef('REPORT')
    end

    File.open($REPORTDIR+"/kanji-flashcards/flashcard.css", 'w') do |f|
      f.write @t['flashcard.css'].apply_ifdef('REPORT')
    end

    return data_json
  end


  def Flashcard.bracket_yomi(y)
    return y.to_s if y.class == Symbol
    if y.kat?
      '[' + y + ']'
    else
      yhead, ytail = y.split('.')
      ytail ||= ''
      '(' + yhead + ')' + ytail
    end
  end


  def Flashcard.make_anki_templates

    # answer

    File.open($REPORTDIR+'/__anki__/templates/answer.html','w') do |f|
      f.write @t['anki-template.html'].with(
        JS_EXT_GARBLED: "<script src='answer.js'></script>".reverse
      ).check.gsub("\n",'').gsub('  ','')
    end

    File.open($REPORTDIR+'/__anki__/media/answer.js','w') do |f|
      f.write @t['flashcard.js'].apply_ifdef('ANKI','ANSWER').with(
        HTML: @t['flashcard.html'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ',''),
        CSS: @t['flashcard.css'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ','').gsub(/\/\*.*?\*\//,'')
      ).check
    end

    # recognition

    File.open($REPORTDIR+'/__anki__/templates/recog.html','w') do |f|
      f.write @t['anki-template.html'].with(
        JS_EXT_GARBLED: "<script src='recog.js'></script>".reverse
      ).check.gsub("\n",'').gsub('  ','')
    end

    File.open($REPORTDIR+'/__anki__/media/recog.js','w') do |f|
      f.write @t['flashcard.js'].apply_ifdef('ANKI','RECOG').with(
        HTML: @t['flashcard.html'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ',''),
        CSS: @t['flashcard.css'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ','').gsub(/\/\*.*?\*\//,'')
      ).check
    end

    # production

    File.open($REPORTDIR+'/__anki__/templates/prod.html','w') do |f|
      f.write @t['anki-template.html'].with(
        JS_EXT_GARBLED: "<script src='prod.js'></script>".reverse
      ).check.gsub("\n",'').gsub('  ','')
    end

    File.open($REPORTDIR+'/__anki__/media/prod.js','w') do |f|
      f.write @t['flashcard.js'].apply_ifdef('ANKI','PROD').with(
        HTML: @t['flashcard.html'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ',''),
        CSS: @t['flashcard.css'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ','').gsub(/\/\*.*?\*\//,'')
      ).check
    end

    FileUtils.copy 'kanji-flashcard/json2/json2.js', $REPORTDIR+'/__anki__/media'
  end

end
