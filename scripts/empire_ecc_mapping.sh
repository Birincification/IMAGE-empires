#!/bin/bash

index=$1
pData=$2
sampleDir=$3
strand=$4

samplesTable2="/home/data/out/EmpiReS/samples.table2"
eccCounts="/home/data/out/EmpiReS/ecc.counts"
diffsplicOut="/home/data/out/diff_splicing_outs/empire.diffsplic.outECC"
diffexpOut="/home/data/out/diff_exp_outs/empire.diffexp.outECC"




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
java -cp /home/software/nlEmpiRe.jar nlEmpiRe.rnaseq.reads.TranscriptInfoBasedGenomicMapper \
-table $samplesTable2 \
-index $index \
-o $eccCounts \
-basedir $sampleDir


## diffexp and das
java -cp /home/software/nlEmpiRe.jar nlEmpiRe.release.EQCInput \
-i $eccCounts \
-samples $samplesTable2 \
-cond2reps $cond2reps \
-diffexpout $diffexpOut \
-o $diffsplicOut

