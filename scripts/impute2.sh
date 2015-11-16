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

function execute_impute_job
{
    # purpose: executes an impute job
    # paramtr: $chr_number  (IN): the chromosome number
    #          $chunk_start (IN): the name of the job to execute
    #          $chunk_end   (IN): the state in which the job is
    #          $directory   (IN): the directory where to execute the impute job
    #   
    local chr_number=$1
    local chunk_start=$2
    local chunk_end=$3
    local directory=$4

    if [ "X${chr_number}" = "X" ];then
	echo "ERROR: chromsome number not specified for imputation step" 1>&2
	exit 1
    fi


    if [ "X${chunk_start}" = "X" ];then
	echo "ERROR: chunk start not specified for imputation step" 1>&2
	exit 1
    fi

    if [ "X${chunk_end}" = "X" ];then
	echo "ERROR: chunk end not specified for imputation step" 1>&2
	exit 1
    fi

    if [ "X${directory}" = "X" ];then
	echo "ERROR: directory  not specified for imputation step" 1>&2
	exit 1
    fi
    
    ROOT_DIR=./
    # pegasus stages all files in the directory
    # where the job executes. DATA_DIR is set to $directory
    # Similary for RESULTS_DIR
    DATA_DIR=./${directory}
    RESULTS_DIR=./${directory}

    IMPUTE2_EXEC=impute2
    
    NE=20000

    GENMAP_FILE=${DATA_DIR}/genetic_map_chr${chr_number}_combined_b37.txt
    HAPS_FILE=${DATA_DIR}/1000GP_Phase3_chr${chr_number}.hap.gz
    LEGEND_FILE=${DATA_DIR}/1000GP_Phase3_chr${chr_number}.legend.gz
    
    GWAS_HAPS_FILE=./${directory}/${STUDY_NAME}.phase.chr${chr_number}.haps

    OUTPUT_FILE=${RESULTS_DIR}/${STUDY_NAME}.chr${chr_number}.pos${chunk_start}-${chunk_end}.impute2
    SUMMARY_FILE=${OUTPUT_FILE}_summary
    DIPLOTYE_FILE=${OUTPUT_FILE}_diplotype_ordering
    INFO_FILE=${OUTPUT_FILE}_info
    INFO_FILE_BY_SAMPLE=${OUTPUT_FILE}_info_by_sample

    if [ ! -d "$RESULTS_DIR" ]; then
	mkdir $RESULTS_DIR
	fi

    echo "Running IMPUTE2 on $chunk_start $chunk_end "
    #STDOUT_FILE=$(mktemp ./impute2.stdout.XXXXXX)
    
    #imputation code can fail if no valid snp are found.
    # handle that

    $IMPUTE2_EXEC \
	-m $GENMAP_FILE \
	-known_haps_g $GWAS_HAPS_FILE \
	-h $HAPS_FILE \
	-l $LEGEND_FILE \
	-Ne $NE \
	-int $chunk_start $chunk_end \
	-o $OUTPUT_FILE \
	-allow_large_regions \
	-seed 1961 

    EC=$?
    echo "Impute2 exited with status $EC for chunk intervale $chunk_start $chunk_end"
	
    
    if [ $(grep -c -v "There are no SNPs in the imputation interval, so there is nothing for IMPUTE2 to analyze; the program will quit now." $SUMMARY_FILE) -gt 0 ]; then
	echo "Creating an empty output files with prefix $OUTPUT_FILE"
	touch $OUTPUT_FILE
	touch $DIPLOTYE_FILE
	touch $INFO_FILE
	touch $INFO_FILE_BY_SAMPLE

    fi

    gzip $OUTPUT_FILE
    
    
}


if [ $# -eq 5 ];then
	echo "impute2.sh: with start and end positions indicated, it will not do internal chunking "

	STUDY_NAME=$1
	CHR=$2
	DIRECTORY=$3
	CHUNK_START=`printf "%.0f" $4`
	CHUNK_END=`printf "%.0f" $5`

	execute_impute_job $CHR $CHUNK_START $CHUNK_END $DIRECTORY
	
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

STUDY_NAME=$1
CHR=$2
DIRECTORY=$3


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
	
	#edited by Lisheng: 11/16/2015
	count=$(awk -v d1="$i" -v d2="$j" '{if (($3 >=d1 )&&($3<=d2)) print $0}' ${STUDY_NAME}.phase.chr${CHR}.haps | wc -l)

	if [ $count > 0 ]
	then
	
		execute_impute_job $CHR $CHUNK_START $CHUNK_END $DIRECTORY
	else
		echo "No SNP in this chunk; impute2 stops" > ${STUDY_NAME}.chr${CHR}.pos${i}-${j}.impute2_summary
		touch ${STUDY_NAME}.chr${CHR}.pos${i}-${j}.impute2_warnings
		touch ${STUDY_NAME}.chr${CHR}.pos${i}-${j}.impute2_info
		touch ${STUDY_NAME}.chr${CHR}.pos${i}-${j}.impute2_info_by_sample
		touch ${STUDY_NAME}.chr${CHR}.pos${i}-${j}.impute2
		gzip ${STUDY_NAME}.chr${CHR}.pos${i}-${j}.impute2
		touch ${STUDY_NAME}.chr${CHR}.pos${i}-${j}.impute2_diplotype_ordering
	fi
done

fi

