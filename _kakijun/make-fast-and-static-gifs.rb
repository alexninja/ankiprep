# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../libs')
$GIFDIR = 'gif'

require 'RMagick'

#----------------------------------------------------------------------------------------

$logfile = File.open(File.basename(__FILE__).sub('.rb','.log'), 'w')

def print str
	$logfile.print str
	Kernel.print str
end

def puts str
	$logfile.puts str
	Kernel.puts str
end

#----------------------------------------------------------------------------------------

Dir.mkdir("#{$GIFDIR}/kanji-fast") unless File.exist?("#{$GIFDIR}/kanji-fast")
Dir.mkdir("#{$GIFDIR}/kanji-static") unless File.exist?("#{$GIFDIR}/kanji-static")

white_p = Magick::Pixel.from_color('white')
gray_p = Magick::Pixel.new(210,210,210,0)
white = (0..199).map { white_p }

files = Dir["#{$GIFDIR}/kanji/u????.gif"]


files.each_with_index do |path,i|

	file = File.basename(path)
	print "#{(i+1).to_s.rjust(4)}/#{files.size}:  #{file}  "

	if File.size(path) == 0
		puts "**skipped** (0 bytes)"
		next
	end

	frames = Magick::ImageList.new(path)
	frame0px = frames[0].get_pixels(0,0,200,200)

	frames.each_with_index do |frame,i|
		px = frame.get_pixels(0,0,1,1)[0]
		if px.red == 0 && px.green == 0 && px.green == 0
			frame.store_pixels(0,0,200,1,white)
			frame.store_pixels(0,199,200,1,white)
			frame.store_pixels(0,0,1,200,white)
			frame.store_pixels(199,0,1,200,white)
		end
		if i > 0
			newpx = frame.get_pixels(0,0,200,200).zip(frame0px).map do |p,p0|
				(p == white_p && p0 != white_p) ? gray_p : p
			end
			frame.store_pixels(0,0,200,200,newpx)
		end
	end

	frames.delay = 28
	frames.write("#{$GIFDIR}/kanji-fast/#{file}")
	frames[0].write("#{$GIFDIR}/kanji-static/#{file}")

	puts "=>  kanji-fast/#{file},  kanji-static/#{file}"

	frames.each {|frame| frame.destroy!}
end

