require 'URI'


module Audio
  MP3LIST_TXT = "#{$RES_DIR}/audio/mp3_list.txt"

  @mp3hash = {}
  File.readlines(MP3LIST_TXT).each do |line|
    m = line.match(/(^\d+\.mp3)\t(.+\.mp3)$/)
    n_mp3, orig_mp3 = m[1], m[2]
    @mp3hash[orig_mp3] = n_mp3
  end

  puts "[Audio] #{@mp3hash.size} mp3 files"

  @n_mp3 = nil
  @orig_mp3 = nil
  @volume = nil
  @timestamp = Time.now

  def Audio.serve(url, s)
    if m = url.match(/^audio\/([a-z]*)\/([0-9]*)\/(.*)$/)
      action, volume, filename = m[1], m[2], m[3]
      if action == 'play'
        @volume = volume
        @orig_mp3 = URI.unescape(filename)
        @n_mp3 = @mp3hash[@orig_mp3]
        puts "\"#{@orig_mp3}\" not found" if @n_mp3 == nil
        @timestamp = Time.now
      end
    end
  end

  def Audio.watchdog_tick
    if Time.now - @timestamp > 0.1 && @n_mp3
      puts "Playing(#{@volume}) | #{@n_mp3} | #{@orig_mp3}"
      `bassplay.exe #{@volume} #{$RES_DIR}\\audio\\#{@n_mp3}`
      @n_mp3, @volume = nil, nil
    end
  end

  def Audio.ding
    p `bassplay.exe 1000 audio\\ding.wav`
  end

end
