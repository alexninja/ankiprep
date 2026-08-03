require 'etc/progress'

module Vocab; module Audio

  print "[Vocab::Audio] loading mp3 list... "
  Progress.new do |pr|
    win_path = "#{$RES_DIR}/audio".gsub('/','\\')
    @mp3list = `cmd /u /c dir /b #{win_path}`
      .force_encoding('utf-16le').encode("utf-8")
      .split("\n").reject(&:empty?).to_set
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
