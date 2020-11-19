#!/bin/bash

sampleDir=$3
empireIndex=$1
table=$2
out=$4

## EC-contextmap
## create table with format
##
## label   condition   fw  rw  strandness
## cond1_00    cond1   cond1_00_1.fastq.gz cond1_00_2.fastq.gz true
## cond1_01    cond1   cond1_01_1.fastq.gz cond1_01_2.fastq.gz true
##
## (-basedir) can be provided - if given all paths in the sample table are interpreted as relative to this directory
## (-nthreads) number of parallel threads used for the mapping, default: 10.
## 
java -cp /home/software/nlEmpiRe.jar nlEmpiRe.rnaseq.reads.TranscriptEQClassWriter \
-table EXAMPLES/simulate_reads/TEST_OUTPUT/sample.table \
-gtf EXAMPLES/Homo_sapiens.GRCh37.75.gtf \
-o EXAMPLES/stem_idealmapping_ecm.counts \
-basedir EXAMPLES/simulate_reads/TEST_OUTPUT/


## diffexp and das
java -cp /home/software/nlEmpiRe.jar nlEmpiRe.release.EQCInput \
-i EXAMPLES/stem_idealmapping_ecm.counts \
-samples EXAMPLES/simulate_reads/TEST_OUTPUT/sample.table \
-cond2reps $cond2reps \
-diffexpout $diffexpOut$method \
-o EXAMPLES/empires_outtable_stem_simulation_on_ideal_mapping.tsv

