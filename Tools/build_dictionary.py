#!/usr/bin/env python3
"""Builds Koubutsu's offline dictionary from EDRDG data.

    Tools/build_dictionary.py [--jmdict JMdict_e.gz] [--kanjidic kanjidic2.xml.gz] [--out DIR]

Downloads JMdict_e and KANJIDIC2 when paths are not given, converts them to one SQLite database and writes
it raw-DEFLATE compressed (Foundation `.zlib`) as `koubutsu_dictionary.sqlite.deflate` in DIR (default
App/Resources/Dictionary). The app decompresses it once on first use.

Data: JMdict and KANJIDIC2 © Electronic Dictionary Research and Development Group, CC BY-SA 4.0
(https://www.edrdg.org/edrdg/licence.html). The generated database is distributed under the same licence.

Schema (version 1):
  meta(key, value)
  entry(id INTEGER PRIMARY KEY, common INTEGER, rank INTEGER, json TEXT)
      json = {"k":[{"t","c","i":[ke_inf]}], "r":[{"t","c","nk","i":[re_inf],"to":[restr]}],
              "s":[{"p":[pos],"g":[gloss],"m":[misc],"f":[field],"d":[dial],"n":note,"sk":[stagk],"sr":[stagr]}]}
  form(key TEXT, entry INTEGER, kanji INTEGER)  -- key = form with katakana folded to hiragana
  kanji(literal TEXT PRIMARY KEY, json TEXT)
      json = {"m":[meaning],"on":[..],"kun":[..],"s":strokes,"g":grade,"f":freq,"j":jlpt}
"""
import argparse, gzip, io, json, os, re, sqlite3, sys, tempfile, urllib.request, zlib
import xml.etree.ElementTree as ET

JMDICT_URL = "http://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz"
KANJIDIC_URL = "https://www.edrdg.org/kanjidic/kanjidic2.xml.gz"
SCHEMA_VERSION = "1"
COMMON_TAGS = {"news1", "ichi1", "spec1", "spec2", "gai1"}
XML_ENTITIES = {"amp", "lt", "gt", "quot", "apos"}
ENTITY = re.compile(r"&([A-Za-z0-9_-]+);")


def fold_kana(text):
    """Katakana → hiragana (the lookup key form)."""
    return "".join(chr(ord(c) - 0x60) if 0x30A1 <= ord(c) <= 0x30F6 else c for c in text)


def entity_free_lines(path):
    """JMdict text with the DOCTYPE removed and DTD entities (&v1;) replaced by their codes (v1)."""
    in_doctype = False
    with gzip.open(path, "rt", encoding="utf-8") as f:
        for line in f:
            if line.startswith("<!DOCTYPE"):
                in_doctype = True
            if in_doctype:
                if line.startswith("]>"):
                    in_doctype = False
                continue
            yield ENTITY.sub(lambda m: m.group(0) if m.group(1) in XML_ENTITIES else m.group(1), line)


class LineStream(io.RawIOBase):
    def __init__(self, lines):
        self.lines, self.buffer = lines, b""

    def readable(self):
        return True

    def readinto(self, b):
        while len(self.buffer) < len(b):
            try:
                self.buffer += next(self.lines).encode("utf-8")
            except StopIteration:
                break
        n = min(len(b), len(self.buffer))
        b[:n], self.buffer = self.buffer[:n], self.buffer[n:]
        return n


def rank_of(priorities):
    ranks = [int(p[2:]) for p in priorities if p.startswith("nf")]
    return min(ranks) if ranks else (50 if COMMON_TAGS & set(priorities) else 99)


def texts(el, tag):
    return [c.text or "" for c in el.findall(tag)]


def build_jmdict(path, db):
    count = 0
    stream = io.BufferedReader(LineStream(entity_free_lines(path)), buffer_size=1 << 20)
    for _, el in ET.iterparse(stream, events=("end",)):
        if el.tag != "entry":
            continue
        seq = int(el.findtext("ent_seq"))
        kanji, readings, senses, priorities = [], [], [], []
        for k in el.findall("k_ele"):
            pri = texts(k, "ke_pri")
            priorities += pri
            item = {"t": k.findtext("keb")}
            if COMMON_TAGS & set(pri): item["c"] = 1
            if k.find("ke_inf") is not None: item["i"] = texts(k, "ke_inf")
            kanji.append(item)
        for r in el.findall("r_ele"):
            pri = texts(r, "re_pri")
            priorities += pri
            item = {"t": r.findtext("reb")}
            if COMMON_TAGS & set(pri): item["c"] = 1
            if r.find("re_nokanji") is not None: item["nk"] = 1
            if r.find("re_inf") is not None: item["i"] = texts(r, "re_inf")
            if r.find("re_restr") is not None: item["to"] = texts(r, "re_restr")
            readings.append(item)
        last_pos = []
        for s in el.findall("sense"):
            pos = texts(s, "pos") or last_pos  # JMdict: pos carries over to following senses
            last_pos = pos
            sense = {"p": pos, "g": texts(s, "gloss")}
            for key, tag in (("m", "misc"), ("f", "field"), ("d", "dial"), ("sk", "stagk"), ("sr", "stagr")):
                values = texts(s, tag)
                if values: sense[key] = values
            note = s.findtext("s_inf")
            if note: sense["n"] = note
            senses.append(sense)
        common = 1 if COMMON_TAGS & set(priorities) else 0
        payload = {"k": kanji, "r": readings, "s": senses}
        db.execute("INSERT INTO entry VALUES (?,?,?,?)",
                   (seq, common, rank_of(priorities), json.dumps(payload, ensure_ascii=False, separators=(",", ":"))))
        keys = {(fold_kana(k["t"]), 1) for k in kanji} | {(fold_kana(r["t"]), 0) for r in readings}
        db.executemany("INSERT INTO form VALUES (?,?,?)", [(key, seq, is_kanji) for key, is_kanji in keys])
        el.clear()
        count += 1
    return count


def build_kanjidic(path, db):
    count = 0
    with gzip.open(path, "rb") as f:
        for _, el in ET.iterparse(f, events=("end",)):
            if el.tag != "character":
                continue
            literal = el.findtext("literal")
            misc = el.find("misc")
            rm = el.find("reading_meaning")
            item = {"m": [], "on": [], "kun": []}
            if rm is not None:
                for group in rm.findall("rmgroup"):
                    item["m"] += [m.text for m in group.findall("meaning") if m.get("m_lang") is None]
                    for r in group.findall("reading"):
                        if r.get("r_type") == "ja_on": item["on"].append(r.text)
                        if r.get("r_type") == "ja_kun": item["kun"].append(r.text)
            if misc is not None:
                for key, tag in (("s", "stroke_count"), ("g", "grade"), ("f", "freq"), ("j", "jlpt")):
                    value = misc.findtext(tag)
                    if value: item[key] = int(value)
            db.execute("INSERT INTO kanji VALUES (?,?)", (literal, json.dumps(item, ensure_ascii=False, separators=(",", ":"))))
            el.clear()
            count += 1
    return count


def fetch(url, directory):
    target = os.path.join(directory, url.rsplit("/", 1)[1])
    if not os.path.exists(target):
        print(f"downloading {url}", file=sys.stderr)
        urllib.request.urlretrieve(url, target)
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--jmdict")
    parser.add_argument("--kanjidic")
    parser.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "App", "Resources", "Dictionary"))
    parser.add_argument("--keep-sqlite", help="also write the uncompressed database here")
    args = parser.parse_args()
    work = tempfile.mkdtemp()
    jmdict = args.jmdict or fetch(JMDICT_URL, work)
    kanjidic = args.kanjidic or fetch(KANJIDIC_URL, work)

    db_path = os.path.join(work, "dictionary.sqlite")
    db = sqlite3.connect(db_path)
    db.executescript("""
        PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF; PRAGMA page_size=4096;
        CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT);
        CREATE TABLE entry(id INTEGER PRIMARY KEY, common INTEGER, rank INTEGER, json TEXT);
        CREATE TABLE form(key TEXT, entry INTEGER, kanji INTEGER);
        CREATE TABLE kanji(literal TEXT PRIMARY KEY, json TEXT);
    """)
    entries = build_jmdict(jmdict, db)
    characters = build_kanjidic(kanjidic, db)
    db.execute("CREATE INDEX form_key ON form(key)")
    meta = {
        "schema": SCHEMA_VERSION,
        "entries": str(entries),
        "kanji": str(characters),
        "source": "JMdict_e, KANJIDIC2 (EDRDG)",
        "licence": "CC BY-SA 4.0 — Electronic Dictionary Research and Development Group",
    }
    db.executemany("INSERT INTO meta VALUES (?,?)", meta.items())
    db.commit()
    db.execute("VACUUM")
    db.close()

    raw = open(db_path, "rb").read()
    if args.keep_sqlite:
        open(args.keep_sqlite, "wb").write(raw)
    compressor = zlib.compressobj(9, zlib.DEFLATED, -15)
    packed = compressor.compress(raw) + compressor.flush()
    os.makedirs(args.out, exist_ok=True)
    out = os.path.join(args.out, "koubutsu_dictionary.sqlite.deflate")
    open(out, "wb").write(packed)
    print(f"{entries} entries, {characters} kanji; sqlite {len(raw)/1e6:.1f} MB → {out} {len(packed)/1e6:.1f} MB")


if __name__ == "__main__":
    main()
