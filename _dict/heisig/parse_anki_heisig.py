f = open("D:/anki_heisig.txt", "rb")
data = f.read()
f.close()
data = data.decode("UTF-8")
data = data.splitlines()

for line in data:
    print line.split('\t')[4]
    break
    
    
    
    
