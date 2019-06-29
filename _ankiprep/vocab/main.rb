require 'set'
require 'json'
require 'edict'
require 'kanjidic'
require 'anki'
require 'misc/utf8'
require 'misc/gray'
require 'misc/template'
require 'misc/progress'
require_relative 'word'
require_relative 'audio'
require_relative 'report/report'



module Vocab

  def self.makeall
    anki_words, rikai_words = Vocab.parse_input()

    Vocab::Report.make_htmls(rikai_words)
    make_anki(rikai_words)

    @vocab_list = Vocab.make_vocab_list(anki_words, rikai_words)
  end

  def self.input_file_present?
    @input_file_present
  end

  def self.vocab_list
    @vocab_list
  end


private

  def self.parse_input
    print "[Vocab] reading #{$ANKIDIR}/vocab.anki... "
    anki_words = Anki.read("#{$ANKIDIR}/vocab.anki").map do |expr,json|
      Word.from_anki(expr,json)
    end
    puts "#{anki_words.size} vocab entries"

    print "[Vocab] reading D:/_rikaichan.txt... "
    rikai_words = []
    if File.exists?("D:/_rikaichan.txt")
      @input_file_present = true
      rikai_words = Utf8::readlines("D:/_rikaichan.txt").map.with_index do |line,i|
        Word.from_line(line, i+1)
      end.compact
      puts
    else
      @input_file_present = false
      puts "Not Found. Will Regenerate Everything in __OUT__!"
    end
    #p (anki.values + rikai.values).map {|ar| ar.size}.to_set

    [ anki_words.freeze, rikai_words.freeze ]
  end


  def self.make_anki(rikai_words)
    rikai_words_good = rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                                   select {|w| !w.error}

    File.open('D:/vocab.[IMPORT].txt','w:UTF-8') do |f|
      rikai_words_good.each do |w|
        hash = Hash.new
        hash['expr'] = w.entries.first.expr
        hash['yomi'] = []
        w.entries.each_with_index do |e,i|
          kana = e.kana.dup
          kana = '~' + kana if !e.priority?
          kana = kana + '*' if i == 0
          alts = e.alts.map {|ar| ar.dup}
          if !Audio.have_file?(w.entries.first.expr, e.kana) &&
              alt_with_audio = alts[1].index {|a| Audio.have_file?(a.gsub('~',''), e.kana)}
            alts[1][alt_with_audio] += '*'
          end
          hash['yomi'] << {
            'kana' => kana,
            'alts' => alts,
            'eigo' => e.eigoc
          }
        end
        json = hash.to_json
        json.gsub! '"expr":', 'expr:'
        json.gsub! '"yomi":', 'yomi:'
        json.gsub! '"kana":', 'kana:'
        json.gsub! '"alts":', 'alts:'
        json.gsub! '"eigo":', 'eigo:'
        f.puts json.split('\"').join('\\\\\"').split("'").join("\\'") + "\t" + hash['expr']
      end
    end

  end


  def self.make_vocab_list(anki_words, rikai_words)
    rikai_words_good = rikai_words.select {|w| w.flags_none? :dupe_in_anki, :dupe_in_rikai}.
                                   select {|w| !w.error}

    (anki_words + rikai_words_good).map do |w|
      entries = w.xref ? w.xref.entries : w.entries
      expr = entries.first.expr
      w2 = Word.new
      w2.expr = expr
      w2.entries = entries
      w2
    end.freeze
  end

end # module


##

class String

  def highlight(substr, cond = true)
    if cond
      self.gsub(substr, "<span class='hl'>" + substr + "</span>")
    else
      self
    end
  end

end

