require 'URI'


module Audio

  @filename = nil
  @volume = nil
  @timestamp = Time.now

  def Audio.serve(url, s)
    if m = url.match(/^audio\/([a-z]*)\/([0-9]*)\/(.*)$/)
      action, volume, filename = m[1], m[2], m[3]
      if action == 'play'
        @filename = filename
        @volume = volume
        @timestamp = Time.now
      end
    end
  end

  def Audio.watchdog_tick
    if Time.now - @timestamp > 0.1 && @filename
      puts "Playing (#{@volume}): #{URI.unescape(@filename)}"
      `bassplay.exe #{@volume} #{$DICT_DIR}\\audio\\#{@filename}`
      @filename, @volume = nil, nil
    end
  end

  def Audio.ding
    p `bassplay.exe 1000 audio\\ding.wav`
  end

end
