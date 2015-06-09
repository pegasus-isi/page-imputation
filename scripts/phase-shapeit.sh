#!/bin/bash
# -- begin --
# This is a simple example of a SGE batch script
#
# request Bourne shell as shell for job
#$ -S /bin/bash
# Use the current directory as the working directory
#$ -cwd

#$1: study name – “testing”
#$2: number of chromosome – “22”
#$3: directory name – “chr22”


# set -x to see on terminal what commands are executed
# only for debugging
set -x


#check for hte number of arguments passed.
if [ $# -lt 2 ];then
    echo "test-shapeit.sh requires at a minimum two arguments: studyname chromosomenumber "
    exit 1
fi 

study_name=$1
chromosome_num=$2
directory=$3

shapeit --input-vcf ./$3/$1.chr$2.recode.vcf.gz --input-ref ./1000GP_Phase3_chr$2.hap.gz ./1000GP_Phase3_chr$2.legend.gz ./1000GP_Phase3.sample --input-map ./genetic_map_chr$2_combined_b37.txt --thread 1 --exclude-snp ./$3/$1.chr$2.duplicate.snp.site.out --effective-size 20000 --output-max ./$3/$1.phase.chr$2.haps ./$3/$1.phase.chr$2.sample --output-log ./$3/$1.phase.chr$2.log

# we test that shapeit ran successfully only on basis of presence of
# error statement in it's log
if grep ERROR ./$3/$1.phase.chr$2.log
then
    #fail on first error 
    set -e
    echo "Errors detected in ./$3/$1.phase.chr$2.log"
    cat ./$3/$1.phase.chr$2.snp.strand.exclude ./$3/$1.chr$2.duplicate.snp.site.out > ./$3/$1.chr$2.duplicate.snp.site.out.new
    mv ./$3/$1.chr$2.duplicate.snp.site.out.new ./$3/$1.chr$2.duplicate.snp.site.out
    shapeit --input-vcf ./$3/$1.chr$2.recode.vcf.gz --input-ref ./1000GP_Phase3_chr$2.hap.gz ./1000GP_Phase3_chr$2.legend.gz ./1000GP_Phase3.sample --input-map ./genetic_map_chr$2_combined_b37.txt --thread 1 --exclude-snp ./$3/$1.chr$2.duplicate.snp.site.out --effective-size 20000 --output-max ./$3/$1.phase.chr$2.haps ./$3/$1.phase.chr$2.sample --output-log ./$3/$1.phase.chr$2.log
    
fi

