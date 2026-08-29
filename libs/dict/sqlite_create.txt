CREATE TABLE kanjidic (
    id INT PRIMARY KEY,
    kanji TEXT,
    eigo TEXT,
    heisig INT,
    stroke_count INT
);

CREATE INDEX idx_kanjidic_kanji ON kanjidic(kanji);

CREATE TABLE yomi (
    id INT PRIMARY KEY,
    yomi TEXT
);

CREATE TABLE j_kanji_yomi (
    id INT,
    kanjidic_id INT,
    yomi_id INT,
    PRIMARY KEY (id, kanjidic_id, yomi_id)
    FOREIGN KEY (kanjidic_id) REFERENCES kanjidic(id),
    FOREIGN KEY (yomi_id) REFERENCES yomi(id),
    UNIQUE (id),
    UNIQUE (kanjidic_id, yomi_id)
);

CREATE TABLE j_kanji_yomi_2 (
    kanji TEXT,
    yomi TEXT,
    UNIQUE (kanji, yomi)
);

CREATE TABLE seki (
    yomi TEXT,
    frag TEXT,
    moji TEXT,
    excl TEXT,
    UNIQUE (yomi, frag, moji, excl)
);
CREATE INDEX idx_seki_moji ON seki(moji);

----



----

CREATE TABLE edict (
    id INT PRIMARY KEY,
    expr TEXT,
    kana TEXT,
    eigo TEXT,
    prio BOOL,
    alts TEXT,
    seki TEXT
);

CREATE INDEX idx_edict_expr ON edict(expr);
CREATE INDEX idx_edict_eigo ON edict(eigo);
CREATE INDEX idx_edict_kana ON edict(kana);

CREATE TABLE j_edict (
    edict_id INT,
    j_kanji_yomi_id INT,
    PRIMARY KEY (edict_id, j_kanji_yomi_id),
    FOREIGN KEY (edict_id) REFERENCES edict(id),
    FOREIGN KEY (j_kanji_yomi_id) REFERENCES j_kanji_yomi(id)
);
