require 'json'
require 'misc/template'
require 'misc/jsontrim'

module Kanji; module Flashcard

  @heisig_list = Dir[$DICT_DIR+"/heisig/*.png"].map {|f| f.match(/\/(\d{4})\.png/)[1].to_i}.to_set

  def self.makeall
    print "[Kanji::Flashcard] generating #{Kanji::Stats.new_kanji.size} html files... "

    FileUtils.mkdir_p $OUTDIR+'/kanji/flashcard'
    FileUtils.mkdir_p $OUTDIR+'/kanji/anki/templates'
    FileUtils.mkdir_p $OUTDIR+'/kanji/anki/media'

    File.open('D:/kanji.[IMPORT].txt','w') do |ankiimp|
      Progress.new(Kanji::Stats.new_kanji.size) do |pr|
        Kanji::Stats.new_kanji.each do |k|
          # create the html flashcard...
          data_json = make_card(k)
          # ... and create a line for importing to kanji.anki (unless it's already there)
          unless Kanji::Stats.known_kanji? k
            # anki wants \\\" and \' so make it happy
            data_json_escaped = data_json.split('\"').join('\\\\\"').split("'").join("\\'")
            ankiimp.puts "#{data_json_escaped}\t#{k}"
          end
          pr.tick
        end
      end
    end

    make_anki_snippets
    make_anki_js

    FileUtils.copy Dir['kanji/flashcard/png/*.png'], $OUTDIR+'/kanji/flashcard'
  end

  def self.make_card(k)
    # creates the kanji's html flashcard in __OUT__/kanji/flashcard/ (for display by server.rb),
    # prepopulated with the data json and the word_counts json.
    # also returns the data json for Anki import txt file

    utf16 = k.utf16_code
    yarr = Kanji::Stats.yarr(k) + [:other]

    on_all, kun_all = Kanjidic.yomi(k).sort_by {|y| Kanji::Stats.yfreq(k,y)}.reverse.partition {|y| y.kat?}
    kun_all = kun_all.partition {|y| ! y.include?('-')}.flatten

    word_counts = Hash.new
    yarr.each do |y|
      word_counts[y] = [ANK,POM,MON,EDI].map {|src| Kanji::Stats.words(src, k, y).size}
    end

    data = Hash.new
    yarr.each do |y|
      yb = bracket_yomi(y)
      data[yb] = Hash.new
      data[yb]['use'] = (word_counts[y].inject(0) {|sum,x| sum+=x} > 0)
      if y.class == String && y.kat?
        data[yb]['freq'] = Kanji::Stats.yfreq(k,y)
      end
      data[yb]['words'] = []
    end
    data['yomi'] = (on_all + kun_all).map {|y| bracket_yomi(y)}
    data['nanori'] = Kanjidic.nanori(k)
    data['eigo'] = Kanjidic.eigo(k).join(', ').sub(", (kokuji)", " (kokuji)")
    data['utf16'] = utf16
    data['kanji'] = k
    kjt = Kanji::Stats.kjt(k)
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

    File.open($OUTDIR+"/kanji/flashcard/k#{k.utf16_code}.html", 'w') do |f|
      f.write $T['kanji/flashcard/flashcard.html'].apply_ifdef('REPORT').with(
        UTF16: utf16,
        DATA: data_json,
        WORD_COUNTS: word_counts_brk.to_json,
        GIFDIR: $DICT_DIR+"/gif",
        HEISIG_DIR: $DICT_DIR+"/heisig",
        HEISIG_PNG: heisig_png,
        HEISIG_IMG_TAG: heisig_img_tag
      ).check
    end

    File.open($OUTDIR+"/kanji/flashcard/flashcard.js", 'w') do |f|
      f.write $T['kanji/flashcard/flashcard.js'].apply_ifdef('REPORT')
    end

    File.open($OUTDIR+"/kanji/flashcard/flashcard.css", 'w') do |f|
      f.write $T['kanji/flashcard/flashcard.css'].apply_ifdef('REPORT')
    end

    return data_json
  end


  def self.bracket_yomi(y)
    return y.to_s if y.class == Symbol
    if y.kat?
      '[' + y + ']'
    else
      yhead, ytail = y.split('.')
      ytail ||= ''
      '(' + yhead + ')' + ytail
    end
  end


  def self.make_anki_snippets
    File.open($OUTDIR+'/kanji/anki/answer.html','w') do |f|
      f.write $T['kanji/flashcard/anki-snippet.html'].with(
        JS_EXT_GARBLED: "<script src='answer.js'></script>".reverse
      ).check.gsub("\n",'').gsub('  ','')
    end
    File.open($OUTDIR+'/kanji/anki/recog.html','w') do |f|
      f.write $T['kanji/flashcard/anki-snippet.html'].with(
        JS_EXT_GARBLED: "<script src='recog.js'></script>".reverse
      ).check.gsub("\n",'').gsub('  ','')
    end
    File.open($OUTDIR+'/kanji/anki/prod.html','w') do |f|
      f.write $T['kanji/flashcard/anki-snippet.html'].with(
        JS_EXT_GARBLED: "<script src='prod.js'></script>".reverse
      ).check.gsub("\n",'').gsub('  ','')
    end
  end

  def self.make_anki_js
    File.open($OUTDIR+'/kanji/anki/answer.js','w') do |f|
      f.write $T['kanji/flashcard/flashcard.js'].apply_ifdef('ANKI','ANSWER').with(
        HTML: $T['kanji/flashcard/flashcard.html'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ',''),
        CSS: $T['kanji/flashcard/flashcard.css'].apply_ifdef('ANKI','ANSWER').check.gsub("\n",'').gsub('  ','').gsub(/\/\*.*?\*\//,'')
      ).check
    end
    File.open($OUTDIR+'/kanji/anki/recog.js','w') do |f|
      f.write $T['kanji/flashcard/flashcard.js'].apply_ifdef('ANKI','RECOG').with(
        HTML: $T['kanji/flashcard/flashcard.html'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ',''),
        CSS: $T['kanji/flashcard/flashcard.css'].apply_ifdef('ANKI','RECOG').check.gsub("\n",'').gsub('  ','').gsub(/\/\*.*?\*\//,'')
      ).check
    end
    File.open($OUTDIR+'/kanji/anki/prod.js','w') do |f|
      f.write $T['kanji/flashcard/flashcard.js'].apply_ifdef('ANKI','PROD').with(
        HTML: $T['kanji/flashcard/flashcard.html'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ',''),
        CSS: $T['kanji/flashcard/flashcard.css'].apply_ifdef('ANKI','PROD').check.gsub("\n",'').gsub('  ','').gsub(/\/\*.*?\*\//,'')
      ).check
    end
  end

end; end
