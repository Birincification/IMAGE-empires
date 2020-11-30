#!/bin/bash

gtf=$1
fasta=$2
fastaIndex=$3

mkdir -p /home/data/indices/empires

## creates index
java -cp /home/software/nlEmpiRe.jar nlEmpiRe.rnaseq.mapping.ExtractTranscriptomeInfo \
 -gtf $gtf \
 -genome $fasta \
 -genomeidx $fastaIndex \
 -o /home/data/indices/empires/empires.index
