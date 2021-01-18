#!/bin/bash

## add xmx as param? -> maybe not good as no user would know what to put?

## index dir needs to be mounted
#index=$1
pData=$1
sampleDir=$2
strand=$3

index="/home/data/indices/empires/empires.index"
samplesTable2="/home/data/out/EmpiReS/samples.table2"
eccCounts="/home/data/out/EmpiReS/ecc.counts"
diffsplicOut="/home/data/out/diff_splicing_outs/empire.diffsplic.outECC"
## diffexpOut="/home/data/out/diff_exp_outs/empire.diffexp.outECC"


## mkdir -p /home/data/out/diff_exp_outs/
mkdir -p /home/data/out/diff_splicing_outs/
mkdir -p /home/data/out/EmpiReS/

## EC-contextmap
## create table with format
##
## label   condition   fw  rw  strandness
## cond1_00    cond1   cond1_00_1.fastq.gz cond1_00_2.fastq.gz true
## cond1_01    cond1   cond1_01_1.fastq.gz cond1_01_2.fastq.gz true
##
echo "label"$'\t'"condition"$'\t'"fw"$'\t'"rw"$'\t'"strandness" > $samplesTable2
sed '1d' $pData | awk -v strand=$strand '{print $1 "\t" $2 "\t" $1 "_1.fastq.gz" "\t" $1 "_2.fastq.gz" "\t" strand}' >> $samplesTable2
#for sample in `cat $sampleList`; do echo $sample$'\t'$sample.bam$'\t'$strand >> $samplesTable ; done


##
## (-basedir) can be provided - if given all paths in the sample table are interpreted as relative to this directory
## (-nthreads) number of parallel threads used for the mapping, default: 10.
## 

## test if output exists
( [ -f "$eccCounts" ] && echo "[INFO] [EMPIRES] $eccCounts already exists; skipping.."$'\n' ) || \
( java -Xmx70G -cp /home/software/nlEmpiRe.jar nlEmpiRe.rnaseq.mapping.TranscriptInfoBasedGenomicMapper \
-table $samplesTable2 \
-index $index \
-o $eccCounts \
-basedir $sampleDir )


## diffexp and das
java -Xmx70G -cp /home/software/nlEmpiRe.jar nlEmpiRe.release.EQCInput \
-i $eccCounts \
-samples $samplesTable2 \
-o $diffsplicOut

