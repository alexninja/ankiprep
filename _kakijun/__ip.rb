require 'socksify/http'

Net::HTTP.SOCKSProxy('127.0.0.1', 9050).start('check.torproject.org') do |http|

  res = http.get('/')

  if res.class == Net::HTTPOK
    puts res.body[/Your IP address appears to be: <b>(.+)<\/b>/, 1]
  end

end