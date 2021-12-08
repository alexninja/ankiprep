
# trims a json string produced by the JSON gem - removes double quotes from ascii-only keys

class String

  def trim_keys(hash)
    str = self.dup
    String.ascii_keys(hash).each do |key|
      str.gsub!('"'+key+'"', key)
    end
    str
  end

private

  def String.ascii_keys(hash)
    ret = []
    hash.each_key do |key|
      ret << key if key.class == String && key.ascii_only?
      ret += ascii_keys(hash[key]) if hash[key].class == Hash
    end
    ret
  end

end
