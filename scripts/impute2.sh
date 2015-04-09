#!/bin/bash
#$ -cwd
#$ -j y
CDIR='pwd'

CHR=$2
CHUNK_START=`printf "%.0f" $3`
CHUNK_END=`printf "%.0f" $4`

ROOT_DIR=./
DATA_DIR=./1000GP_Phase3/
RESULTS_DIR=./$5/RESULTS/

IMPUTE2_EXEC=./impute_v2.3.1_x86_64_dynamic/impute2

NE=20000

GENMAP_FILE=${DATA_DIR}genetic_map_chr${CHR}_combined_b37.txt
HAPS_FILE=${DATA_DIR}1000GP_Phase3_chr${CHR}.hap.gz
LEGEND_FILE=${DATA_DIR}1000GP_Phase3_chr${CHR}.legend.gz

GWAS_HAPS_FILE=./$5/$1.phase.chr${CHR}.haps

OUTPUT_FILE=${RESULTS_DIR}$1.chr${CHR}.pos${CHUNK_START}-${CHUNK_END}.impute2

if [ ! -d "$RESULTS_DIR" ]; then
	mkdir $RESULTS_DIR
fi

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

