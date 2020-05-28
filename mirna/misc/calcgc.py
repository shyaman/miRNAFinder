from Bio import SeqIO
import pandas as pd


for record in SeqIO.parse("/mirna/gc.mfe", "fasta"):
    print(record.id)
    print(record.seq)