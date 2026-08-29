CREATE TABLE kanji (
    id INT PRIMARY KEY,
    moji TEXT,
    eigo TEXT,
    heisig INT,
    stroke_count INT
);
CREATE INDEX idx_kanj_moji ON kanji(moji);

CREATE TABLE seki (
    yomi TEXT,
    frag TEXT,
    moji TEXT,
    UNIQUE (yomi, frag, moji)
);
CREATE INDEX idx_seki_moji ON seki(moji);

----

CREATE TABLE edict (
    id INT PRIMARY KEY,
    expr TEXT,
    kana TEXT,
    eigo TEXT,
    prio BOOL
);
CREATE INDEX idx_edict_expr ON edict(expr);
CREATE INDEX idx_edict_kana ON edict(kana);
CREATE INDEX idx_edict_eigo ON edict(eigo);
