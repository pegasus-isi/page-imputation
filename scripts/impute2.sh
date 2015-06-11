#!/bin/bash
#$ -cwd
#$ -j y

# ensure that the script fails on error
set -e

# set pipefial to ensure that we don't succeed when we use the tee command
set -o pipefail 


# set -x to see on terminal what commands are executed
# only for debugging
set -x

#$1: study name – “testing”
#$2: number of chromosome – “22”
#$3: chunk start
#$4: chunk end
#$5: directory name – “chr22”

#check for the number of arguments passed.
#if [ $# -lt 4 ];then
#    echo "impute2.sh requires at a minimum four arguments: studyname chromosomenumber chunk_start chunk_end "
#    exit 1
#fi 

if [ $# -eq 5 ];then
	echo "impute2.sh: with start and end positions indicated, it will not do internal chunking "

	study_name=$1
	CHR=$2
	CHUNK_START=`printf "%.0f" $3`
	CHUNK_END=`printf "%.0f" $4`
	directory=$5

	ROOT_DIR=./
        # pegasus stages all files in the directory
        # where the job executes. DATA_DIR is set to $directory
        # Similary for RESULTS_DIR
	DATA_DIR=./${directory}
	RESULTS_DIR=./${directory}
	
	IMPUTE2_EXEC=impute2

	NE=20000

	GENMAP_FILE=${DATA_DIR}/genetic_map_chr${CHR}_combined_b37.txt
	HAPS_FILE=${DATA_DIR}/1000GP_Phase3_chr${CHR}.hap.gz
	LEGEND_FILE=${DATA_DIR}/1000GP_Phase3_chr${CHR}.legend.gz
	
	GWAS_HAPS_FILE=./${directory}/${study_name}.phase.chr${CHR}.haps
	
	OUTPUT_FILE=${RESULTS_DIR}/${study_name}.chr${CHR}.pos${CHUNK_START}-${CHUNK_END}.impute2

	if [ ! -d "$RESULTS_DIR" ]; then
	    mkdir $RESULTS_DIR
	fi

	echo "Running IMPUTE2 on $CHUNK_START $CHUNK_END "

	$IMPUTE2_EXEC \
	    -m $GENMAP_FILE \
	    -known_haps_g $GWAS_HAPS_FILE \
	    -h $HAPS_FILE \
	    -l $LEGEND_FILE \
	    -Ne $NE \
	    -int $CHUNK_START $CHUNK_END \
	    -o $OUTPUT_FILE \
	    -allow_large_regions \
	    -seed 1961

	gzip $OUTPUT_FILE

fi

if [ $# -eq 3 ];then
	echo "impute2.sh: will start internal chunking "

chr1=248956422
chr2=242193529
chr3=198295559
chr4=190214555
chr5=181538259
chr6=170805979
chr7=159345973
chr8=145138636
chr9=138394717
chr10=133797422
chr11=135086622
chr12=133275309
chr13=114364328
chr14=107043718
chr15=101991189
chr16=90338345
chr17=83257441
chr18=80373285
chr19=58617616
chr20=63025520
chr21=48129895
chr22=51304566

study_name=$1
CHR=$2
directory=$3


string="chr$CHR"
size=${!string}
echo "DEBUG: size set to $size"
## stops here

i=1

for ((i=1; i<$size; i=i+5000000))
do
	j=$(($i+4999999))
	if [ $j -gt $size ]
	then
		j=$size
	fi
	CHUNK_START=$i
	CHUNK_END=$j
	
	ROOT_DIR=./
# pegasus stages all files in the directory
# where the job executes. DATA_DIR is set to $directory
# Similary for RESULTS_DIR
	DATA_DIR=./${directory}
	RESULTS_DIR=./${directory}

	IMPUTE2_EXEC=impute2

	NE=20000

	GENMAP_FILE=${DATA_DIR}/genetic_map_chr${CHR}_combined_b37.txt
	HAPS_FILE=${DATA_DIR}/1000GP_Phase3_chr${CHR}.hap.gz
	LEGEND_FILE=${DATA_DIR}/1000GP_Phase3_chr${CHR}.legend.gz

	GWAS_HAPS_FILE=./${directory}/${study_name}.phase.chr${CHR}.haps

	OUTPUT_FILE=${RESULTS_DIR}/${study_name}.chr${CHR}.pos${CHUNK_START}-${CHUNK_END}.impute2

	if [ ! -d "$RESULTS_DIR" ]; then
	mkdir $RESULTS_DIR
	fi

	echo "Running IMPUTE2 on $CHUNK_START $CHUNK_END "
	STDOUT_FILE=$(mktemp ./impute2.stdout.XXXXXX)
	
	#imputation code can fail if no valid snp are found.
	# handle that

	$IMPUTE2_EXEC \
		-m $GENMAP_FILE \
		-known_haps_g $GWAS_HAPS_FILE \
		-h $HAPS_FILE \
		-l $LEGEND_FILE \
		-Ne $NE \
		-int $CHUNK_START $CHUNK_END \
		-o $OUTPUT_FILE \
		-allow_large_regions \
		-seed 1961 \
	        | tee $STDOUT_FILE

	EC=$?
	echo "Impute2 exited with status $EC"

	if [ $EC -ne 0 ]; then
	    echo "impute code failed with status $EC"
	    
        fi
	
	if [ $(grep -c -v "There are no SNPs in the imputation interval, so there is nothing for IMPUTE2 to analyze; the program will quit now." $STDOUT_FILE) -gt 0 ]; then
	    echo "Creating an empty output file $OUTPUT_FILE"
	    touch $OUTPUT_FILE
	else
	    #trigger failure in the script		
	    exit 1
	fi
	gzip $OUTPUT_FILE
	rm $STDOUT_FILE

done

fi

