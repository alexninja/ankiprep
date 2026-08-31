CREATE TABLE kanji (
    moji TEXT,
    eigo TEXT,
    heisig INT,
    stroke_count INT,
    UNIQUE (moji)
);
CREATE INDEX idx_kanj_moji ON kanji(moji);

CREATE TABLE yomi (
    moji TEXT,
    yomi TEXT,
    UNIQUE (moji, yomi)
);
CREATE INDEX idx_yomi_moji ON yomi(moji);

----

CREATE TABLE edict (
    expr TEXT,
    kana TEXT,
    eigo TEXT,
    prio BOOL,
    UNIQUE (expr, kana, eigo, prio)
);
CREATE INDEX idx_edict_expr ON edict(expr);
CREATE INDEX idx_edict_kana ON edict(kana);
CREATE INDEX idx_edict_eigo ON edict(eigo);
