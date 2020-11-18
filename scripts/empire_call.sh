#!/bin/bash

##needs samples.table to be present in EmpiReS dir

gtf=$1
pData=$2
sampleList=$3
splic=$4
exp=$5
strand=$6

samplesTable="/home/data/out/EmpiReS/samples.table"
cond2reps="/home/data/out/EmpiReS/empiReS.cond2reps"
diffexpOut="/home/data/out/diff_exp_outs/empire.diffexp.out"
diffsplicOut="/home/data/out/diff_splicing_outs/empire.diffsplic.out"
eqclassOut="/home/data/out/EmpiReS/eqclass.counts"

mkdir -p /home/data/out/EmpiReS

#create samplesTable from sampleList
#echo 'id\tbam\tstrandness' > $samplesTable
echo "id"$'\t'"bam"$'\t'"strandness" > $samplesTable
for sample in `cat $sampleList`; do echo $sample$'\t'$sample.bam$'\t'$strand >> $samplesTable ; done

#create con2reps file from p_data
sed -e '1d' $pData | awk '{print $2 "\t" $1}' > $cond2reps



##star quant and twopass; hisat
for dir in "/home/data/out/STAR/quant" "/home/data/out/STAR/2pass" "/home/data/out/HISAT/dta"; do
method="`echo $dir | cut -d '/' -f 5``echo $dir | cut -d '/' -f 6`"

cd $dir
( [ -f "$dir"/eqclass.counts ] && echo "$'\n'[INFO] [EMPIRES] $dir/eqclass.counts already exists; skipping.." ) || \
( echo " [INFO] [EMPIRES] Starting eq extract in $dir" && /home/scripts/empire.sh eqextract -gtf $gtf -table $samplesTable -o $dir/eqclass.counts > /home/data/out/EmpiReS/eqclass_$method.log )


( [ -f "$diffexpOut$method" ] && echo "[INFO] [EMPIRES] $diffexpOut$method already exists; skipping.."$'\n' ) || \
( echo "[INFO] [EMPIRES] Starting differential processing in $dir" && /home/scripts/empire.sh eqinput -samples $samplesTable -cond2reps $cond2reps -diffexpout $diffexpOut$method -o $diffsplicOut$method -eqclasscounts $dir/eqclass.counts -trues $splic -truediffexp $exp && echo "done with $dir")
done




##trans quantifiers
for dir in "/home/data/out/SALMON" "/home/data/out/KALLISTO/alignment" "/home/data/out/STRINGTIE"; do
method="`echo $dir | cut -d '/' -f 5`"

cd $dir

( [ -f "$diffsplicOut$method" ] && echo "[INFO] [EMPIRES] $diffsplicOut$method already exists; skipping.."$'\n' ) || \
( echo "[INFO] [EMPIRES] Starting processing in $dir" && /home/software/jdk-13.0.1/bin/java -Xmx60000M -cp /home/software/nlEmpiRe.jar nlEmpiRe.input.TranscriptEstimateInput -cond2reps $cond2reps -gtf $gtf -trestimateroot $dir -trues $splic -o $diffsplicOut$method )
echo "done with $dir"
done



#head -3 ../samples.table
#id      bam     strandness
#cond1_00        cond1_00.bam    true
#cond1_01        cond1_01.bam    true 

#cat ../empiReS.cond2reps
#cond1   cond1_00
#cond1   cond1_01
