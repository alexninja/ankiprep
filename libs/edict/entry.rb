module Edict

  class Entry
    attr_reader :expr, :kana, :eigo
    attr_writer :alts, :priority, :fake  # to accommodate creation of fake Entries

    @@markers = File.readlines(File.dirname(__FILE__)+'/edict_markers.txt').map {|line| line.split[0]}
    (1..100).to_a.each {|x| @@markers << x.to_s}

    def initialize(expr, kana, eigo)
      @expr, @kana, @eigo = expr, kana, eigo
      [@expr, @kana, @eigo].each {|v| v.freeze}
      @priority = @eigo.include? '(P)'
      @eigoc = nil
      @seki = nil
      @alts = nil
      @fake = false
    end

    def eigoc  #lazy
      return @eigoc if @eigoc
      e = @eigo.dup
      e.scan(/\(.+?\)/).each do |part|
        if part[1..-2].split(',').all? {|p| @@markers.include? p}
          e.sub!(part, '')
          e.sub!('  ', ' ')
        end
      end
      @eigoc = e.split('/').delete_if {|x| x.empty?}.map {|x| x[0..0]==' ' ? x[1..-1] : x}.join('; ')
    end

    def seki  #lazy
      # NB assumes 'yomi/parse' was already require'd by calling code ! ! !
      @seki ||= Yomi.parse(self)
    end

    def alts  #lazy
      # find alternate kana for [@expr,@eigoc] (if any), and alternate expr's for [@kana,@eigoc] (if any)
      # result is an array of two arrays of strings; non-priority strings prefixed with '~'
      # e.g. for 言う いう returns: [["ゆう"], ["~謂う","~云う"]]
      @alts ||= [
        Edict.lookup_expr(@expr).
          select {|e| e.eigoc == self.eigoc && e.kana != @kana}.
          partition {|e| e.priority?}.
          flatten.
          map {|e| (e.priority?) ? e.kana : '~'+e.kana} ,
        Edict.lookup_kana(@kana).
          select {|e| e.eigoc == self.eigoc && e.expr != @expr}.
          partition {|e| e.priority?}.
          flatten.
          map {|e| (e.priority?) ? e.expr : '~'+e.expr}
      ]
    end

    def ==(other)
      @expr == other.expr and @kana == other.kana and @eigoc == other.eigoc
    end

    def priority?
      @priority
    end

    def fake?
      @fake
    end

    def priority=(forcepr)
      @priority = forcepr
    end

    # for use as a Hash key

    def hash
      [expr, kana].hash
    end

    def eql? other
      [expr, kana] == [other.expr, other.kana]
    end

  end

end #module
