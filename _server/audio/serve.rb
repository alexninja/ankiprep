
$AUDIODIR = 'D:\Japanese\_dict\audio'


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
      result = `bassplay.exe #{@volume} #{$AUDIODIR}\\#{@filename}` # no idea why this works without quotes (filename contains spaces)
      result.chomp!
      puts result
      if result.include? 'File Not Found'
#        puts `bassplay.exe 10000 audio\\ding.wav` # while this doesn't
      end
      @filename, @volume = nil, nil
    end
  end

end
