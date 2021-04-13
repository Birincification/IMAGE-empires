#!/bin/bash

gtf=$1
fasta=$2
fastaIndex=$3
log=$4

mkdir -p /home/data/indices/empires

[[ -f "/home/data/indices/empires/empires.index" ]] && echo "index already exists.." && exit 0

watch pidstat -dru -hHl '>>' $log/empires_index-$(date +%s).pidstat & wid=$!

## creates index
java -cp /home/software/nlEmpiRe.jar nlEmpiRe.rnaseq.mapping.ExtractTranscriptomeInfo \
 -gtf $gtf \
 -genome $fasta \
 -genomeidx $fastaIndex \
 -o /home/data/indices/empires/empires.index

kill -15 $wid
