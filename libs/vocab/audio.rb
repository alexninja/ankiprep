
module Vocab; module Audio

  print "[Vocab::Audio] loading mp3 list... "
  if File.exist? "#{$RES_DIR}/.marshal/audio.marshal"
    @mp3list = File.open("#{$RES_DIR}/.marshal/audio.marshal", 'rb') {|f| Marshal.load(f)}
  else
    win_path = "#{$RES_DIR}/audio".gsub('/','\\')
    `cmd /u /c dir /b #{win_path} > mp3list.tmp`
    @mp3list = File.read('mp3list.tmp', mode:'r:UTF-16LE:UTF-8').split("\n").to_set
    FileUtils.rm 'mp3list.tmp'
    unless @mp3list.empty?
      print "marshaling... "
      FileUtils.mkdir_p "#{$RES_DIR}/.marshal"
      File.open("#{$RES_DIR}/.marshal/audio.marshal", 'wb') {|f| Marshal.dump(@mp3list, f)}
    end
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
