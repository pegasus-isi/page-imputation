#!/bin/bash
#$ -cwd
#$ -j y

# ensure that the script fails on error
set -e

# set -x to see on terminal what commands are executed
# only for debugging
set -x

#$1: study name – “testing”
#$2: number of chromosome – “22”
#$3: chunk start
#$4: chunk end
#$5: directory name – “chr22”

#check for hte number of arguments passed.
if [ $# -lt 4 ];then
    echo "impute2.sh requires at a minimum four arguments: studyname chromosomenumber chunk_start chunk_end "
    exit 1
fi 


study_name=$1
CHR=$2
CHUNK_START=`printf "%.0f" $3`
CHUNK_END=`printf "%.0f" $4`
directory=$5

ROOT_DIR=./
# pegasus stages all files in the directory
# where the job executes. DATA_DIR is set to $directory
# Similary for RESULTS_DIR
DATA_DIR=./${directory}/
RESULTS_DIR=./${directory}

IMPUTE2_EXEC=impute2

NE=20000

GENMAP_FILE=${DATA_DIR}genetic_map_chr${CHR}_combined_b37.txt
HAPS_FILE=${DATA_DIR}1000GP_Phase3_chr${CHR}.hap.gz
LEGEND_FILE=${DATA_DIR}1000GP_Phase3_chr${CHR}.legend.gz

GWAS_HAPS_FILE=./${directory}/${study_name}.phase.chr${CHR}.haps

OUTPUT_FILE=${RESULTS_DIR}${study_name}.chr${CHR}.pos${CHUNK_START}-${CHUNK_END}.impute2

if [ ! -d "$RESULTS_DIR" ]; then
	mkdir $RESULTS_DIR
fi

echo "Running IMPUTE2"

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

