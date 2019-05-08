# tries to fixup mangled .sub files by putting lines in the order indicated by their timings
# e.g. eps 4 and 7 here http://www.d-addicts.com/forum/viewtopic_74874.htm have some lines in the wrong order
# NB that still leaves those 2 episodes with some spurious lines which I replaced by hand post-factum
#
# typical line looks like this:
#
# 75
# 00:03:55,830 --> 00:03:58,530
# 研究に発揮されるべきだと 考えますが？
#


File
  .read(ARGV.shift, mode: 'r:UTF-8')
  .split(/\n\n/)
  .map do |x|
    m = x.split(/(\d{1,4})\n(\d\d:\d\d:\d\d,\d\d\d --> \d\d:\d\d:\d\d,\d\d\d)\n(.+)/m)
    raise "WTF!" unless m
    [m[1], m[2], m[3]]
  end
  .sort_by do |no,time,line|
    time.split('-->').first.gsub(':','').gsub(',','').to_i
  end
  .each_with_index do |x, i|
    time, line = x[1], x[2]
    puts i+1
    puts time
    puts line
    puts
  end
