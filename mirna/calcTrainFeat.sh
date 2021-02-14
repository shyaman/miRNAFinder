#!/bin/bash

# ./calcTrainFeat posSeq.fa negSeq.fa
set -e

# (cd microPred && \
# ./calculateHere.sh $1 $1_micropred_train && \
# ./calculateHere.sh $2 $2_micropred_train)

(cd motif && \
mkdir -p pos && \
./calculate50motifs.sh ../microPred/data/$1 pos)

(cd motif && \
mkdir -p neg && \
./calculate50motifs.sh ../microPred/data/$1 neg)

# (cd motif && python3 motiffeat.py -p pos/meme.xml -n neg/meme.xml -i ../microPred/data/$1 -o $1_motif_train )
# (cd triplet && python3 triplet_elements.py -i ../microPred/data/$1 -o $1_triplet_train)
# python3 combine.py -m microPred/$1_micropred_train.xlsx -n motif/$1_motif_train.xlsx -t triplet/$1_triplet_train.xlsx -o $1_feat