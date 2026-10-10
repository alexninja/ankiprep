require 'fileutils'

AUDIODIR = '../../_res/audio'
MP3LIST_TXT = "#{AUDIODIR}/mp3_list.txt"
MP3DIR_TMP = 'mp3dir.tmp'

win_path = "#{AUDIODIR}".gsub('/','\\')
`cmd /u /c dir /b #{win_path}\\*.mp3 > #{MP3DIR_TMP}`

File.open(MP3LIST_TXT,'w:utf-8') do |mp3list|
  File.open(MP3DIR_TMP,'rb:UTF-16LE'){ |file| file.readlines }.each_with_index do |mp3,i|
    mp3list.puts "%06i.mp3\t%s" % [i+1, mp3.chop]
  end
end

FileUtils.rm MP3DIR_TMP
