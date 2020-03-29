import re
import numpy as np
import sys, getopt

inputfile = ''
outputfile = ''
argv = sys.argv[1:]
try:
    opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
except getopt.GetoptError:
    print ('test.py -i <inputfile> -o <outputfile>')
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print ('test.py -i <inputfile> -o <outputfile>')
        sys.exit()
    elif opt in ("-i", "--ifile"):
        inputfile = arg
    elif opt in ("-o", "--ofile"):
        outputfile = arg
print ('Input file is :', inputfile)
print ('Output file is :', outputfile)

file1 = open(inputfile, 'r') 
Lines = file1.read().splitlines() 
header = re.split(r'\s+',Lines[0],18)
fam = []
# Strips the newline character 
for line in Lines[1:]: 
    fam.append(re.split(r'\s+',line,17))

fam  = pd.DataFrame(fam,columns=header)
fam['E-value'] = pd.to_numeric(fam['E-value'])
idx = fam.groupby(['query_name'])['E-value'].transform(min) == fam['E-value']
fam = fam[idx][['query_name','target_name']]
fam = fam.rename(columns={'query_name': 'ID','target_name':'family'})
fam.to_excel(outputfile,index=False)
