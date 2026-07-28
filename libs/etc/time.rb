def format_time(time)
  [time/3600, time/60 % 60, time % 60].map {|t| t.to_i}.select {|t| t != 0}.map{|t| t.to_s.rjust(2,'0')}.join(':') + ' s'
end
