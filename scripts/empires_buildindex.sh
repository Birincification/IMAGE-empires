#!/bin/bash

gtf=$1
fasta=$2
fastaIndex=$3
out=$4

## creates index
java -cp /home/software/nlEmpiRe.jar nlEmpiRe.rnaseq.mapping.ExtractTranscriptomeInfo -gtf $gtf -genome $fasta -genomeidx $fastaIndex -o $out