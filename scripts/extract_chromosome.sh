#! /bin/bash
#$ -S /bin/bash
#$ -cwd

mkdir $3

./vcftools_0.1.12b/bin/vcftools --chr $2 --gzvcf BioMe-AA_ILLUMINA.vcf.gz --max-alleles 2 --remove-indels --recode --out ./$3/$1.chr$2
./extra-duplicate.pl ./$3/$1.chr$2.recode.vcf > ./$3/$1.chr$2.duplicate.snp.site.out


./tabix-0.2.6/bgzip ./$3/$1.chr$2.recode.vcf
./tabix-0.2.6/tabix ./$3/$1.chr$2.recode.vcf.gz

