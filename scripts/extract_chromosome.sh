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
    echo "extract_chromsome.sh requires at a minimum two arguments: studyname chromosomenumber "
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

mkdir -p $directory

#./vcftools_0.1.12b/bin/vcftools --chr $2 --gzvcf BioMe-AA_ILLUMINA.vcf.gz --max-alleles 2 --remove-indels --recode --out ./$3/$1.chr$2
#./extra-duplicate.pl ./$3/$1.chr$2.recode.vcf > ./$3/$1.chr$2.duplicate.snp.site.out

recode_vcf=./${directory}/${study_name}.chr${chromosome_num}.recode.vcf

echo "Running vcftools"
vcftools --chr $2 --gzvcf ${study_name}.${chromosome_num}.vcf.gz --max-alleles 2 --remove-indels --recode --out ./${directory}/${study_name}.chr${chromosome_num}

#vcftools exits with a 0 exitcode even when output file is not created
if [ ! -e $recode_vcf ];then
    echo "ERROR: vcftools did not create output recode.vcf file $recode_vcf"
    exit 1
fi


echo "Figuring out duplicates"
extra-duplicate.pl ./${recode_vcf} > ./${Directory}/${study_name}.chr${chromosome_num}.duplicate.snp.site.out


#./tabix-0.2.6/bgzip ./$3/$1.chr$2.recode.vcf
#./tabix-0.2.6/tabix ./$3/$1.chr$2.recode.vcf.gz
bgzip ./${directory}/${study_name}.chr${chromosome_num}.recode.vcf
tabix ./${directory}/${study_name}.chr${chromosome_num}.recode.vcf.gz

