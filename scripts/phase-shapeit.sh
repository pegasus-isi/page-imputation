#!/bin/bash
#$ -S /bin/bash
# Use the current directory as the working directory
#$ -cwd

# ensure that the script fails on error
set -e

# set -x to see on terminal what commands are executed
# only for debugging
set -x

#$1: study name – “testing”
#$2: number of chromosome – “22”
#$3: directory name – “chr22”

#check for hte number of arguments passed.
if [ $# -lt 2 ];then
    echo "phase-shapeit.sh requires at a minimum two arguments: studyname chromosomenumber "
    exit 1
fi 

study_name=$1
chromosome_num=$2
directory=$3

#default output directory .
if [ "X${directory}" = "X" ];then
    echo "Setting output directory to current directory $PWD "
    directory="."
fi


#./shapeit --input-vcf ./$3/$1.chr$2.recode.vcf.gz --input-ref ./1000GP_Phase3/1000GP_Phase3_chr$2.hap.gz ./1000GP_Phase3/1000GP_Phase3_chr$2.legend.gz ./1000GP_Phase3/1000GP_Phase3.sample --input-map ./1000GP_Phase3/genetic_map_chr$2_combined_b37.txt --thread 1  --exclude-snp ./$3/$1.chr$2.snps.total.exclude --effective-size 20000 --output-max ./$3/$1.phase.chr$2.haps ./$3/$1.phase.chr$2.sample --output-log ./$3/$1.phase.chr$2.log

echo "Phasing shapeit"
shapeit --input-vcf ./${directory}/${study_name}.chr${chromosome_num}.recode.vcf.gz --input-ref ./1000GP_Phase3/1000GP_Phase3_chr${chromosome_num}.hap.gz ./1000GP_Phase3/1000GP_Phase3_chr${chromosome_num}.legend.gz ./1000GP_Phase3/1000GP_Phase3.sample --input-map ./1000GP_Phase3/genetic_map_chr${chromosome_num}_combined_b37.txt --thread 1  --exclude-snp ./${directory}/${study_name}.chr${chromosome_num}.snps.total.exclude --effective-size 20000 --output-max ./${directory}/${study_name}.phase.chr${chromosome_num}.haps ./${directory}/${study_name}.phase.chr${chromosome_num}.sample --output-log ./${directory}/${study_name}.phase.chr${chromosome_num}.log

