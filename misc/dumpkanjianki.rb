# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')

# dump existing kanji.anji, look up frequency of each kanji using Kanji::Stats,
# recreate kanji import txt file in order of that frequency (to start kanji study anew)


require 'json'
require 'anki'
require_relative 'kanji/main'
Kanji::Stats.init


$JSON_KEYS = %w[use freq words other yomi nanori eigo utf16 kanji kjt comp_freq comp_rank].
  sort {|a,b| (a.include? b) ? -1 : (b.include? a) ? 1 : 0}.reverse # foobarbaz before bar

def strip_quotes(json)
  ret = json.dup
  $JSON_KEYS.each {|key| ret.gsub!("\"#{key}\":", "#{key}:")}
  ret
end

def add_quotes(json)
  ret = json.dup
  $JSON_KEYS.each {|key| ret.gsub!("#{key}:", "\"#{key}\":")}
  ret
end

def to_json_object(json)
  JSON.parse(add_quotes(json))
end

#---

$errors_anki = []

File.open(File.basename(__FILE__)+'.txt','w') do |outfile|

  $anki_kanji = Anki.read("#{$ANKIDIR}/kanji.anki").map do |k,json|
    json = strip_quotes(json)
    if to_json_object(json)['kanji'] != k
      $errors_anki << "mismatch: [#{kanji.inspect}] | " + to_json_object(json)['kanji']
    end
    [k,json]
  end.to_h

  puts "#{$anki_kanji.size} kanji, #{$errors_anki.size} errors"

  k_freq = $anki_kanji.keys.map {|k|
    freq =
      Kanji::Stats.words(POM, k, :all).inject(0) {|sum,wi| sum+=wi.n} +
      Kanji::Stats.words(MON, k, :all).inject(0) {|sum,wi| sum+=wi.n} +
      Kanji::Stats.words(EDI, k, :all).inject(0) {|sum,wi| sum+=wi.n}
    [k,freq]
  }.
  sort_by {|k,freq| freq}.
  reverse

  k_freq.each_with_index {|pair,idx|
    k = pair[0]
    json = $anki_kanji[k]
    comp_freq = pair[1]
    comp_rank = idx+1
    new_json = json.sub("\",kanji:\"", "\",comp_freq:#{comp_freq},comp_rank:#{comp_rank},kanji:\"")
    if to_json_object(new_json)['comp_freq'] != comp_freq
      puts "#{k} expected comp_freq: #{comp_freq}"
      puts new_json
    end
    if to_json_object(new_json)['comp_rank'] != comp_rank
      puts "#{k} expected comp_rank: #{comp_rank}"
      puts new_json
    end
    outfile.puts "#{new_json}\t#{k}"
  }

end
