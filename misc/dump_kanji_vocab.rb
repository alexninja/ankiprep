# an attempt to dump all vocab from kanji.anki for use in vocab.anki
#===================================================================

# it was an interesting idea, but there is a TON of weird stuff in my kanji.anki
# not to mention alternative kanji that end up just getting added

$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

require 'json' # gem
require 'anki'

words = Anki.read("#{$ANKIDIR}/kanji.anki").map do |kanji,json|
  json_q = json.gsub('use:',    '"use":'   ).
                gsub('freq:',   '"freq":'  ).
                gsub('words:',  '"words":' ).
                gsub('other:',  '"other":' ).
                gsub('yomi:',   '"yomi":'  ).
                gsub('nanori:', '"nanori":').
                gsub('eigo:',   '"eigo":'  ).
                gsub('utf16:',  '"utf16":' ).
                gsub('kanji:',  '"kanji":' ).
                gsub('kjt:',    '"kjt":'   )

  data = JSON.parse(json_q)

  data.each do |key,val|
    if val.class == Hash
      val['words'].each do |kana,expr,eigo|
        kana.gsub!('[','')
        kana.gsub!(']','')
        kana.gsub!('(','')
        kana.gsub!(')','')
        kana.gsub!('*','')
        puts "#{expr}\t#{kana}\t#{eigo}"
      end
    end
  end

end

