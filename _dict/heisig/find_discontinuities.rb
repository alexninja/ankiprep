prev = 0

Dir['*.png'].each do |file|
  this = file.split('.')[0].to_i
  if this - prev > 1
    puts this
  end
  prev = this
end