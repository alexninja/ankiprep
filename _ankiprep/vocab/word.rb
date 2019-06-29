module Vocab

  class Word

    attr_accessor :expr, :kana, :entries, :flags, :line, :lineno, :xref, :error

    def initialize
      # NB @expr and @kana reflect input line, otherwise are *empty* and deduced from @entries.first
      @expr, @kana, @entries = nil, nil, []
      @flags = Set.new
      @line, @lineno = nil, nil
      @xref = nil
      @error = nil
    end

    def flags_all? *x
      x.all? {|x| @flags.include? x}
    end

    def flags_any? *x
      x.any? {|x| @flags.include? x}
    end

    def flags_none? *x
      x.none? {|x| @flags.include? x}
    end


    @@anki       = Hash.new
    @@anki_alts  = Hash.new
    @@rikai      = Hash.new
    @@rikai_alts = Hash.new

    def add_to(where)
      main, alts = case where
        when :anki then [@@anki, @@anki_alts]
        when :rikai then [@@rikai, @@rikai_alts]
      end
      main[@entries.first.expr] = self unless main.has_key? @entries.first.expr
      @entries.each do |e|
        e.alts.last.each do |a|
          alts[a.sub('~','')] = self unless alts.has_key? a.sub('~','')
        end
      end
    end

    def check_dupes!(where)
      main, alts, flag = case where
        when :anki then [@@anki, @@anki_alts, :dupe_in_anki]
        when :rikai then [@@rikai, @@rikai_alts, :dupe_in_rikai]
      end
      if flags_any? :exact_expr
        if main.has_key?(@expr)
          @xref = main[@expr]
          @flags << flag
          return true
        end
      elsif flags_any? :exact_kana, :skip_edict #this needs to be fixed when I'm clearheaded
        return false unless main.has_key? @expr
        if main[@expr].entries.any? {|e| e.kana == @kana}
          @xref = main[@expr]
          @flags << flag
          return true
        end
      else
        if main.has_key?(@expr)
          @xref = main[@expr]
          @flags << flag
          return true
        end
        if alts.has_key?(@expr)
          @xref = alts[@expr]
          @flags << flag
          @flags << :dupe_in_alts
          return true
        end
      end
      false
    end


    def Word.from_anki(expr, json)
      w = Word.new
      json.gsub! 'expr:', '"expr":'
      json.gsub! 'yomi:', '"yomi":'
      json.gsub! 'kana:', '"kana":'
      json.gsub! 'alts:', '"alts":'
      json.gsub! 'eigo:', '"eigo":'
      data = JSON.parse(json)
      if expr != data['expr']
        warning = "expr mismatch: expr=\"#{expr}\" data.expr=\"#{data['expr']}\""
        puts warning
        #File.open('log.txt','a') {|f| f.puts warning}
      end
      w.expr = data['expr']
      w.entries = data['yomi'].map do |y|
        kana, alts, eigo = y['kana'], y['alts'], y['eigo']
        priority = (kana[0] != '~')
        kana = kana.gsub('~','').gsub('*','').gsub('!','')
        entry = Edict::Entry.new(expr, kana, eigo)
        entry.priority = priority
        entry.alts = alts.map {|ar|
          ar.map {|a| a.gsub('*','').gsub('!','')}
        }
        entry
      end
      w.add_to :anki
      w
    end


    def Word.from_line(line, lineno)

      if m = line.match(/^(.+)\t(.+)\t(.+)$/)
        expr, kana, eigo = m[1], m[2], m[3]
      elsif m = line.match(/\s*(.+?)\s+\u3010(.+?)\u3011\s+(.+)/)
        expr, kana, eigo = m[1], m[2], m[3]
        expr = expr.split('; ').sort_by {|e| e.chars.count {|c| Kanjidic.kanji?(c)}}.reverse[0]
      elsif m = line.match(/^(.+)\t(.+)$/)
        if m[2].ascii_only?
          expr, kana, eigo = m[1], m[1], m[2]
        else
          expr, kana, eigo = m[1], m[2], nil
        end
      elsif !line.include?(' ') && !line.include?("\t")
        expr, kana, eigo = line, nil, nil
      else
        return nil
      end

      return nil if expr.ascii_only?

      w = Word.new

      if expr[0] == '*'
        expr = expr[1..-1]
        w.flags << :skip_edict
      end

      if expr[0] == '!'
        expr = expr[1..-1]
        w.flags << :exact_expr
      end

      if kana && kana[0] == '!'
        kana = kana[1..-1]
        w.flags << :exact_kana
      end

      w.expr = expr
      w.kana = kana
      w.line = line
      w.lineno = lineno

      return w if w.check_dupes! :anki
      return w if w.check_dupes! :rikai

      if w.flags_all? :skip_edict
        # use this exact expr, kana and eigo
        raise ":skip_edict (*) entry should have both kana and eigo (#{lineno})" unless (kana && eigo)
        entry = Edict::Entry.new(expr, kana, eigo)
        entry.priority = true
        entry.alts = [[],[]]
        entry.fake = true
        w.entries = [ entry ]

      else
        # Edict lookup, see input.png
        ent1, ent2 = Edict.lookup_expr(expr).partition {|e| e.kana == kana}
        entries = ent1 + ent2.partition {|e| e.priority?}.flatten

        if entries.empty?
          w.error = "Not found in Edict: #{expr}"
          w.flags << :not_in_edict
          return w
        end

        process_expr = true

        if entries.first.kana == kana
          if entries.first.priority? || w.flags_all?(:exact_kana)
            process_expr = false
          end
        else
          if w.flags_all? :exact_kana
            w.error = "No such kana: [#{kana}], but have: [" + entries.map {|e| e.kana}.join(', ') + "]"
          w.flags << :not_in_edict
            return w
          end
        end

        if process_expr
          if entries.none? {|e| e.priority?} && w.flags_none?(:exact_expr)
            entries.each do |e|
              if expr_p = e.alts.last.partition {|a| a[0] != '~'}.first.first
                entries = Edict.lookup_expr(expr_p)
                break
              end
            end
          end
          entries = entries.partition {|e| e.priority?}.flatten
          w.flags << :alt_expr if entries.first.expr != expr
          w.flags << :alt_kana if kana && entries.first.kana != kana
        end

        # of multiple entries, if any, with the same eigo, retain only the first one
        # we will later find the discarded entries in the one preserved entry's `.alts`
        entries_uniq_eigo = []
        entries.each do |e|
          entries_uniq_eigo << e unless entries_uniq_eigo.any? {|e2| e2.eigoc == e.eigoc}
        end

        w.entries = entries_uniq_eigo
      end

      w.add_to :rikai
      w
    end

  end # class

end # module
