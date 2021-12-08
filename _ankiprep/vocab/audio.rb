
module Vocab; module Audio

  if File.exist? 'vocab/mp3list.marshal'
    print "[Vocab::Audio] loading mp3 list... "
    @mp3list = File.open('vocab/mp3list.marshal', 'rb') {|f| Marshal.load(f)}
  else
    print "[Vocab::Audio] getting mp3 list... "
    `cmd /u /c dir /b D:\\Japanese\\_dict\\audio > vocab\\mp3list.tmp`
    @mp3list = File.read('vocab/mp3list.tmp', mode:'r:UTF-16LE:UTF-8').split("\n").to_set
    FileUtils.rm 'vocab/mp3list.tmp'
    print "saving... "
    File.open('vocab/mp3list.marshal', 'wb') {|f| Marshal.dump(@mp3list, f)}
  end
  puts "#{@mp3list.size} files"

public

  def self.have_file? expr, kana
    mp3 = "#{kana} - #{expr}.mp3"
    @mp3list.include? mp3      
  end

  def self.have? w
    entries = w.xref ? w.xref.entries : w.entries
    return false if entries.empty?
    have_file? entries.first.expr, entries.first.kana
  end

  def self.html_marker expr, kana
    if have_file? expr, kana
      "<span class='audio'>♪</span>"
    else
      ''
    end
  end

end; end
