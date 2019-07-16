require 'misc/template'

module Vocab

  def self.serve(url, s)
    if m = url.match(/^vocab_DE$/)
      s.print "HTTP/1.1 200/OK\r\n"
      s.print "Content-type: text/html\r\n\r\n"
      s.print File.read('D:/Dev/ankiprep/_ankiprep_DE/__OUT__/vocab_DE.html')

    elsif m = url.match(/^vocab_DE\/ico\/(.+\.ico)/)
      path = "vocab/ico/#{m[1]}"
      s.print "HTTP/1.1 200/OK\r\n"
      s.print "Content-Type: image/png\r\n"
      s.print "Accept-Ranges: bytes\r\n"
      s.print "Content-Length: #{File.size(path)}\r\n\r\n"
      s.print open(path,'rb') {|io| io.read}
    end

  end

end # module
