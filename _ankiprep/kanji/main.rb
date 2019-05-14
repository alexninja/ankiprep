require 'misc/template'
require 'misc/urlify'
require_relative 'stats'
require_relative 'wordlist/format'
require_relative 'flashcard/format'
require_relative 'report/report'


module Kanji

  def Kanji.makeall
    Kanji::Stats.init
    Kanji::Flashcard.makeall
    Kanji::Wordlist.makeall
    Kanji::Report.make_htmls
  end

end
