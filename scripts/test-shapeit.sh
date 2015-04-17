#! /bin/bash
#$ -S /bin/bash
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
    echo "test-shapeit.sh requires at a minimum two arguments: studyname chromosomenumber "
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


#./shapeit -check --input-vcf ./$3/$1.chr$2.recode.vcf.gz --input-ref ./1000GP_Phase3/1000GP_Phase3_chr$2.hap.gz ./1000GP_Phase3/1000GP_Phase3_chr$2.legend.gz ./1000GP_Phase3/1000GP_Phase3.sample --thread 1 --exclude-snp ./$3/$1.chr$2.duplicate.snp.site.out --output-log ./$3/$1.chr$2.alignments

echo "Checking shapeit"
shapeit -check --input-vcf ./${directory}/${study_name}.chr${chromosome_num}.recode.vcf.gz --input-ref ./1000GP_Phase3/1000GP_Phase3_chr${chrmosome_num}.hap.gz ./1000GP_Phase3/1000GP_Phase3_chr${chromosome_num}.legend.gz ./1000GP_Phase3/1000GP_Phase3.sample --thread 1 --exclude-snp ./${directory}/${study_name}.chr${chromosome_num}.duplicate.snp.site.out --output-log ./${directory}/${study_name}.chr${chromosome_num}.alignments

strand_exclude=./${directory}/${study_name}.chr${chromosome_num}.alignments.snp.strand.exclude

#shapeit exists with a 0 exitcode even when output file is not created
if [ ! -e $strand_exclude ];then
    echo "ERROR: shapeit did not create output strand.exclude file $strand_exclude"
    exit 1
fi


#cat ./$3/$1.chr$2.alignments.snp.strand.exclude ./$3/$1.chr$2.duplicate.snp.site.out > ./$3/$1.chr$2.snps.total.exclude
echo "Combining duplicates"
cat ./${directory}/${study_name}.chr${chromosome_num}.alignments.snp.strand.exclude ./${directory}/${study_name}.chr${chromosome_num}.duplicate.snp.site.out > ./${directory}/${study_name}.chr${chromosome_num}.snps.total.exclude

