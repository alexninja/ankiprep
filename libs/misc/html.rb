#require 'template'

class Html < Hash

  def initialize(path)
    Dir["#{path}/*.html"].each do |f|
      name = f.split('/').last.split('.')[0]
      data = File.read(f, mode:'r:UTF-8')
      self[name] = StringTemplate.new(data).freeze
    end
  end

  def Html.make_tmpl(f)
    data = File.read(f, mode:'r:UTF-8')
    StringTemplate.new(data).freeze
  end

  class StringTemplate < String
    def with(hash)
      s = self.dup
      hash.each {|from,to| s.gsub!('$'+from.to_s, to.to_s)}
      s
    end

    def check
      raise "template still contains '$' symbols" if self.include? '$'
      self
    end

    def apply_ifdef(*symbols)
      blocks = []
      ret = []
      self.split("\n").each_with_index do |line,i|
        if m = line.match(/^#ifdef (.+)$/)
          block = m[1].gsub(' ','')
          blocks << block
        elsif line == '#endif'
          if blocks.empty?
            raise "#{i+1}: #endif without preceding #ifdef"
          else
            blocks = blocks[0..-2]
          end
        else
          ret << line if blocks == [] ||
            blocks.all? do |b|
              b_or = b.split('||')
              b_and = b.split('&&')
              if b_or.size > 1
                b_or.any? {|b_| symbols.include? b_}
              elsif b_and.size > 1
                b_and.all? {|b_| symbols.include? b_}
              else
                symbols.include? b
              end
            end
        end
      end
      unless blocks.empty?
        loose_blocks = blocks.map {|b| "\#ifdef #{b}"}.join(', ')
        raise "reached end of file, no closing #endif for {#{loose_blocks}}"
      end
      StringTemplate.new(ret.join("\n"))
    end
  end

end
