#!/bin/bash
# -- begin --
# This is a simple example of a SGE batch script
#
# request Bourne shell as shell for job
#$ -S /bin/bash
# Use the current directory as the working directory
#$ -cwd


./shapeit --input-vcf ./$3/$1.chr$2.recode.vcf.gz --input-ref ./1000GP_Phase3/1000GP_Phase3_chr$2.hap.gz ./1000GP_Phase3/1000GP_Phase3_chr$2.legend.gz ./1000GP_Phase3/1000GP_Phase3.sample --input-map ./1000GP_Phase3/genetic_map_chr$2_combined_b37.txt --thread 1  --exclude-snp ./$3/$1.chr$2.snps.total.exclude --effective-size 20000 --output-max ./$3/$1.phase.chr$2.haps ./$3/$1.phase.chr$2.sample --output-log ./$3/$1.phase.chr$2.log

