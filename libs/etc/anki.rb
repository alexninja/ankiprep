require 'sqlite3'


module Anki

  Entry = Struct.new(:json, :marker)

  def Anki.read(filename)

    entries = Hash.new {|h,k| h[k] = Entry.new(nil, nil)}
    db = SQLite3::Database.new(filename)

    db.execute('select factId, value from fields') do |row|
      factId, value = row[0], row[1].chomp
      if value.include? '{'
        json = value.gsub('&quot;','"')
        abort '*' if entries[factId].json
        entries[factId].json = json
      else
        marker = value
        abort '*' if entries[factId].marker
        entries[factId].marker = marker
      end
    end

    # sanity check
    entries.each do |factId, entry|
      abort if entry.json == nil || entry.marker == nil
    end

    # convert to hash of the type {marker=>json}
    # marker is `expr` field in vocab.anki, `kanji` field in kanji.anki
    h = Hash.new
    entries.values.each do |entry|
      h[entry.marker] = entry.json
    end

    h
  end

end

