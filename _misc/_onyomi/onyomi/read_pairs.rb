require 'misc/chomp_utf8'

def read_pairs(filename)
  File.readlines(filename).map do |line|
    if m = line.chomp_utf8.match(/(.*)\t(.*)/)
      [m[1], m[2]]
    else
      nil
    end
  end.
    compact
end
