# ./calculateHere.sh input_file output_file
perl progs/microPred.pl $1
python3 micropredid.py -i $1 -o $2 