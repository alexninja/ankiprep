require 'RMagick'
require 'socksify/http'


def extract_first_frame(src)
  img = Magick::Image.read(src)[0]
  img.write(src.split('.')[0] + '-static.gif')
end


def fetch_gif(k)

  Dir.mkdir('gif') unless File.exist?('gif')

  utf16 = k.utf16_code.upcase
  imgname = "gif/u#{utf16}.gif"

  puts "Fetching #{k} (#{utf16}) #{Time.now}..."

  Net::HTTP.SOCKSProxy('127.0.0.1', 9050).start('kakijun.main.jp') do |http|

    utf8_code = k.bytes.map {|b| '%' + b.to_s(16).upcase}.join
    res = http.get('/main/u_kensaku.cgi?KANJI=' + utf8_code)

    if res.class != Net::HTTPFound
      p res
      exit
    end

    p res.body

    if m = res.body.match(/The document has moved <a href=\"\.\.\/page\/(.+)\.html\">here<\/a>/m)
      gif_path = '/gif/' + m[1] + '.gif'
      res = http.get(gif_path)
      File.open(imgname,'wb') {|f| f.write res.body}
      extract_first_frame(imgname)
      return 'OK'

    elsif res.body.include? '/main/u_nodata.html'
      File.open(imgname,'wb').close
      return 'nodata'

    else
      return '<font color=red><b>unknown error</b></font>'
    end

  end

end
