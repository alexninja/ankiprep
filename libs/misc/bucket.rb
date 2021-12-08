# a hash class to hold "anything" Javascript-style (obj.field instead of obj["field"])
# with a really weird "dump as json" method

class Bucket

  def initialize
    @h = Hash.new
  end

  def method_missing(m, *args)
    if m[-1] == '='
      @h[m[0..-2].to_sym] = args[0]
    else
      @h[m]
    end
  end

  def json
    '{' +
      @h.to_a.map do |k,v|
        k.to_s + ':' +
          if v.class == Bucket
            v.json
          else
            v.inspect
          end
      end.
        join(',') +
    '}'
  end

end
