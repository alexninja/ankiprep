AUDIODIR = '../../_res/audio'
MP3LIST_TXT = "#{AUDIODIR}/mp3_list.txt"

puts "In AUDIODIR = \"#{AUDIODIR}\""

mp3_list = File.readlines(MP3LIST_TXT)

mp3_to_rename = mp3_list.map do |line|
  m = line.match(/(^\d+\.mp3)\t(.+\.mp3)$/)
  n_mp3, orig_mp3 = m[1], m[2]
  if File.exist? "#{AUDIODIR}/#{n_mp3}"
    nil
  else
    [n_mp3, orig_mp3]
  end
end.compact

files_skipped = mp3_list.size - mp3_to_rename.size
puts "Skipped #{files_skipped} files."

time_started = Time.now
files_renamed = 0

mp3_to_rename.each do |n_mp3, orig_mp3|
  files_renamed += 1
  files_to_rename = mp3_to_rename.size - files_renamed
  time_elapsed = Time.now - time_started
  avg_time_per_file = time_elapsed / files_renamed
  eta = avg_time_per_file * files_to_rename
  h,m,s = eta.to_i/60/60, eta.to_i/60%60, eta.to_i%60
  print "[ETA %d:%02d:%02d] [files_to_rename %d] [avg_time_per_file %fs] " % [h,m,s, files_to_rename, avg_time_per_file]
  puts "#{n_mp3} <- \"#{orig_mp3}\""
  cmd = "git mv \"#{AUDIODIR}/#{orig_mp3}\" \"#{AUDIODIR}/#{n_mp3}\""
  `#{cmd}`
end
