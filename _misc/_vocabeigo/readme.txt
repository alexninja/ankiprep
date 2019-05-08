(note for historical purposes; conversion has already been done)

This thing adds eigo to vocab.anki, which I foolishly decided to avoid early on and resulted in
nothing but wasted time and struggling to read the japanese definitions.

1. export from vocab.anki "facts into tab-separated file", name it vocab-exp.txt, copy into this dir
2. run vocabeigo.rb, this will produce vocab-with-eigo.txt
3. add an 'eigo' field to vocab.anki (via Anki's gui)
4. copy vocab.anki itself into this dir too
5. run run-franki.bat, this will modify vocab.anki to now include the eigo
6. copy vocab.anki back to where it belongs, enjoy cramming with eigo