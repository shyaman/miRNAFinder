from Bio import SeqIO
import pandas as pd
import re
from collections import Counter

def calcAGUC(seq):
  freq = Counter(seq)
  length = len(seq)
  return freq['G'], freq['C'], length

leng = []
mfe = []
id = []
gc = []
for record in SeqIO.parse("/mirna/gc.mfe", "fasta"):
    id.append(record.id)
    x = re.search(r"(\w+)[(|)|.]+[+-]?([0-9]*[.]?[0-9]+)", str(record.seq))
    mfe.append(float(x.group(2)))
    seq = x.group(1)
    leng.append(len(seq))
    G,C,l = calcAGUC(seq)
    gc.append((G+C)/l*100)

dict = {'id': id, 'len': leng, 
        'mfe': mfe,'GC':gc}  
pd.DataFrame(dict).to_excel('gc.xlsx',index=False)