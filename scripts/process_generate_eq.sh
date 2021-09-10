#!/bin/bash -x

echo $@
params=("$@")

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=
LONGOPTS=index:,pdata:,samples:,out:,nthread:,log:,strand:,hisat2,star,kallisto,salmon,contextmap,stringtie,ecc,ideal,gtf:,salmonstar,paired

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"
contextmap=n ideal=n hisat2=n star=n kallisto=n salmon=n stringtie=n ecc=n salmonstar=n
paired=''
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
		--index)
        	index="$2"
            shift 2
            ;;
		--pdata)
            pdata="$2"
            shift 2
            ;;
        --samples)
            samples="$2"
            shift 2
            ;;
        --out)
            out="$2"
            shift 2
            ;;
        --nthread)
            nthread="$2"
            shift 2
            ;;
        --gtf)
            gtf="$2"
            shift 2
            ;;
		--log)
			log="$2"
			shift 2
			;;
		--strand)
			strand="$2"
			shift 2
			;;
	    --hisat2)
            hisat2=y
            shift
            ;;
        --star)
            star=y
            shift
            ;;
        --kallisto)
            kallisto=y
            shift
            ;;
        --salmon)
            salmon=y
            shift
            ;;
        --salmonstar)
            salmonstar=y
            shift
            ;;
        --contextmap)
            contextmap=y
            shift
            ;;
        --stringtie)
            stringtie=y
            shift
            ;;
        --ecc)
            ecc=y
            shift
            ;;
        --ideal)
            ideal=y
            shift
            ;;
		--paired)
			paired="y"
			shift
			;;
        --)
            shift
            break
            ;;
        *)
            shift
            ;;
    esac
done

index="$index/empires/empires.index"
samplesTable="$out/EMPIRES/samples.table"
samplesTable2="$out/EMPIRES/samples.table2"
cond2reps="$out/EMPIRES/cond2reps"


eccCounts="$out/EMPIRES/ecc.counts"
diffsplicOut="$out/diff_splicing_outs/empire.diffsplic.out"
diffexpOut="/home/data/out/diff_exp_outs/empire.diffexp.out"

jcall="java -Xmx70G -cp /home/software/nlEmpiRe.jar"

dir=$(basename $out)
name=$(basename $out)

mkdir -p /home/data/out/diff_exp_outs/
mkdir -p $out/diff_splicing_outs/
mkdir -p $out/EMPIRES/

if [[ "$strand" = "null" ]]; then
	strand=
fi


#head -3 ../samples.table
#id      bam     strandness
#cond1_00        cond1_00.bam    true
#cond1_01        cond1_01.bam    true 
#
#cat ../cond2reps
#cond1   cond1_00
#cond1   cond1_01
#
## create samplesTable from sampleList
## echo 'id\tbam\tstrandness' > $samplesTable
( [ -f "$samplesTable" ] && echo "$'\n'[INFO] [EMPIRES] $samplesTable already exists; skipping.." ) || \
	( echo "id"$'\t'"bam"$'\t'"strandness" > $samplesTable &&
	sed '1d' $pdata | awk -v strand=$strand '{print $1 "\t" $1 ".bam" "\t" strand}' >> $samplesTable )

## create con2reps file from p_data
( [ -f "$cond2reps" ] && echo "$'\n'[INFO] [EMPIRES] $cond2reps already exists; skipping.." ) || \
	( sed -e '1d' $pdata | awk '{print $2 "\t" $1}' > $cond2reps )


if [[ "$ecc" = "y" ]]; then
	## EC-contextmap
	## create table with format
	##
	## label   condition   fw  rw  strandness
	## cond1_00    cond1   cond1_00_1.fastq.gz cond1_00_2.fastq.gz true
	## cond1_01    cond1   cond1_01_1.fastq.gz cond1_01_2.fastq.gz true
	##
	( [ -f "$samplesTable2" ] && echo "$'\n'[INFO] [EMPIRES] $samplesTable2 already exists; skipping.." ) || \
		((	if [[ "$paired" = "y" ]]; then 
				echo "label"$'\t'"condition"$'\t'"fw"$'\t'"rw"$'\t'"strandness" > $samplesTable2 && sed '1d' $pdata | awk -v strand=$strand '{print $1 "\t" $2 "\t" $1 "_1.fastq.gz" "\t" $1 "_2.fastq.gz" "\t" strand}' >> $samplesTable2 
			else
				echo "label"$'\t'"condition"$'\t'"fw"$'\t'"strandness" > $samplesTable2 &&sed '1d' $pdata | awk -v strand=$strand '{print $1 "\t" $2 "\t" $1 ".fastq.gz" "\t" strand}' >> $samplesTable2 
			fi
		))
	#for sample in `cat $sampleList`; do echo $sample$'\t'$sample.bam$'\t'$strand >> $samplesTable ; done

	##
	## (-basedir) can be provided - if given all paths in the sample table are interpreted as relative to this directory
	## (-nthreads) number of parallel threads used for the mapping, default: 10.
	## 

	watch pidstat -dru -hlH >> $log/empires_${name}_ecc_eqextract-$(date +%s).pidstat & wid=$!

	## test if output exists
	( [ -f "$eccCounts" ] && echo "[INFO] [EMPIRES] $eccCounts already exists; skipping.."$'\n' ) || \
		( java -Xmx70G -cp /home/software/nlEmpiRe.jar nlEmpiRe.rnaseq.mapping.TranscriptInfoBasedGenomicMapper \
		-table $samplesTable2 \
		-index $index \
		-nthreads $nthread \
		-o $eccCounts \
		-basedir $samples )

	kill -15 $wid
	watch pidstat -dru -hlH >> $log/empires_${name}_ecc_diff_exp_splic-$(date +%s).pidstat & wid=$!

	## diffexp and das
	java -Xmx70G -cp /home/software/nlEmpiRe.jar nlEmpiRe.release.EQCInput \
		-i $eccCounts \
		-samples $samplesTable2 \
		-o ${diffsplicOut}ECC

	kill -15 $wid
fi

if [[ "$hisat2" = "y" ]]; then
	dir=$out/HISAT/dta
	method="HISAT"
	cd $dir

	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_eqextract-$(date +%s).pidstat & wid=$!

	( [ -f "$dir"/$method.eqclass.counts ] && echo "$'\n'[INFO] [EMPIRES] $dir/eqclass.counts already exists; skipping.." ) || \
	( echo " [INFO] [EMPIRES] Starting eq extract in $dir" && \
		$jcall nlEmpiRe.rnaseq.reads.TranscriptEQClassWriter -gtf $gtf \
		-table $samplesTable -o $dir/$method.eqclass.counts >> $out/EMPIRES/eqclass_$method.log )

	kill -15 $wid
	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_diff_exp_splic-$(date +%s).pidstat & wid=$!

	( [ -f "$diffsplicOut$method" ] && echo "[INFO] [EMPIRES] $diffsplicOut$method already exists; skipping.."$'\n' ) || \
	( echo "[INFO] [EMPIRES] Starting diff processing in $dir" && \
		$jcall nlEmpiRe.release.EQCInput -samples $samplesTable2 \
		 -o $diffsplicOut$method -i $dir/$method.eqclass.counts )
	
	kill -15 $wid
fi

if [[ "$star" = "y" ]]; then
	dir=$out/STAR/quant
	method="STAR"
	cd $dir

	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_eqextract-$(date +%s).pidstat & wid=$!

	( [ -f "$dir"/$method.eqclass.counts ] && echo "$'\n'[INFO] [EMPIRES] $dir/eqclass.counts already exists; skipping.." ) || \
	( echo " [INFO] [EMPIRES] Starting eq extract in $dir" && \
		$jcall nlEmpiRe.rnaseq.reads.TranscriptEQClassWriter -gtf $gtf \
		-table $samplesTable -o $dir/$method.eqclass.counts >> $out/EMPIRES/eqclass_$method.log )

	kill -15 $wid
	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_diff_exp_splic-$(date +%s).pidstat & wid=$!

	( [ -f "$diffsplicOut$method" ] && echo "[INFO] [EMPIRES] $diffsplicOut$method already exists; skipping.."$'\n' ) || \
	( echo "[INFO] [EMPIRES] Starting diff processing in $dir" && \
		$jcall nlEmpiRe.release.EQCInput -samples $samplesTable2 \
		 -o $diffsplicOut$method -i $dir/$method.eqclass.counts )
	
	kill -15 $wid
fi

if [[ "$contextmap" = "y" ]]; then
	dir=$out/CONTEXTMAP
	method="CONTEXTMAP"
	cd $dir

	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_eqextract-$(date +%s).pidstat & wid=$!

	( [ -f "$dir"/$method.eqclass.counts ] && echo "$'\n'[INFO] [EMPIRES] $dir/eqclass.counts already exists; skipping.." ) || \
	( echo " [INFO] [EMPIRES] Starting eq extract in $dir" && \
		$jcall nlEmpiRe.rnaseq.reads.TranscriptEQClassWriter -gtf $gtf \
		-table $samplesTable -o $dir/$method.eqclass.counts >> $out/EMPIRES/eqclass_$method.log )

	kill -15 $wid
	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_diff_exp_splic-$(date +%s).pidstat & wid=$!

	( [ -f "$diffsplicOut$method" ] && echo "[INFO] [EMPIRES] $diffsplicOut$method already exists; skipping.."$'\n' ) || \
	( echo "[INFO] [EMPIRES] Starting diff processing in $dir" && \
		$jcall nlEmpiRe.release.EQCInput -samples $samplesTable2 \
		 -o $diffsplicOut$method -i $dir/$method.eqclass.counts )
	
	kill -15 $wid
fi

if [[ "$ideal" = "y" ]]; then
	dir=$out/IDEAL
	method="IDEAL"
	cd $dir

	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_eqextract-$(date +%s).pidstat & wid=$!

	( [ -f "$dir"/$method.eqclass.counts ] && echo "$'\n'[INFO] [EMPIRES] $dir/eqclass.counts already exists; skipping.." ) || \
	( echo " [INFO] [EMPIRES] Starting eq extract in $dir" && \
		$jcall nlEmpiRe.rnaseq.reads.TranscriptEQClassWriter -gtf $gtf \
		-table $samplesTable -o $dir/$method.eqclass.counts >> $out/EMPIRES/eqclass_$method.log )

	kill -15 $wid
	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_diff_exp_splic-$(date +%s).pidstat & wid=$!

	( [ -f "$diffsplicOut$method" ] && echo "[INFO] [EMPIRES] $diffsplicOut$method already exists; skipping.."$'\n' ) || \
	( echo "[INFO] [EMPIRES] Starting diff processing in $dir" && \
		$jcall nlEmpiRe.release.EQCInput -samples $samplesTable2 \
		 -o $diffsplicOut$method -i $dir/$method.eqclass.counts )
	
	kill -15 $wid
fi

if [[ "$salmonstar" = "y" ]]; then
	dir=$out/SALMON/STAR
	method="SALMON_STAR"
	cd $dir

	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_trestimate-$(date +%s).pidstat & wid=$!

	( [ -f "$diffsplicOut$method" ] && echo "[INFO] [EMPIRES] $diffsplicOut$method already exists; skipping.."$'\n' ) || \
	( echo "[INFO] [EMPIRES] Starting processing in $dir" && \
		$jcall nlEmpiRe.input.TranscriptEstimateInput -cond2reps $cond2reps -gtf $gtf -trestimateroot $dir -o $diffsplicOut$method )

	kill -15 $wid
fi

if [[ "$salmon" = "y" ]]; then
	dir=$out/SALMON/READS
	method="SALMON_READS"
	cd $dir

	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_trestimate-$(date +%s).pidstat & wid=$!

	( [ -f "$diffsplicOut$method" ] && echo "[INFO] [EMPIRES] $diffsplicOut$method already exists; skipping.."$'\n' ) || \
	( echo "[INFO] [EMPIRES] Starting processing in $dir" && \
		$jcall nlEmpiRe.input.TranscriptEstimateInput -cond2reps $cond2reps -gtf $gtf -trestimateroot $dir -o $diffsplicOut$method )

	kill -15 $wid
fi

if [[ "$kallisto" = "y" ]]; then
	dir=$out/KALLISTO/quant
	method="KALLISTO"
	cd $dir

	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_trestimate-$(date +%s).pidstat & wid=$!

	( [ -f "$diffsplicOut$method" ] && echo "[INFO] [EMPIRES] $diffsplicOut$method already exists; skipping.."$'\n' ) || \
	( echo "[INFO] [EMPIRES] Starting processing in $dir" && \
		$jcall nlEmpiRe.input.TranscriptEstimateInput -cond2reps $cond2reps -gtf $gtf -trestimateroot $dir -o $diffsplicOut$method )

	kill -15 $wid
fi

if [[ "$stringtie" = "y" ]]; then
	dir=$out/STRINGTIE
	method="STRINGTIE"
	cd $dir

	watch pidstat -dru -hlH >> $log/empires_${name}_${method}_trestimate-$(date +%s).pidstat & wid=$!

	( [ -f "$diffsplicOut$method" ] && echo "[INFO] [EMPIRES] $diffsplicOut$method already exists; skipping.."$'\n' ) || \
	( echo "[INFO] [EMPIRES] Starting processing in $dir" && \
		$jcall nlEmpiRe.input.TranscriptEstimateInput -cond2reps $cond2reps -gtf $gtf -trestimateroot $dir -o $diffsplicOut$method )

	kill -15 $wid
fi