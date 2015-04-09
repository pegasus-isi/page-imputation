#! /bin/bash
#$ -S /bin/bash
#$ -cwd


./shapeit -check --input-vcf ./$3/$1.chr$2.recode.vcf.gz --input-ref ./1000GP_Phase3/1000GP_Phase3_chr$2.hap.gz ./1000GP_Phase3/1000GP_Phase3_chr$2.legend.gz ./1000GP_Phase3/1000GP_Phase3.sample --thread 1 --exclude-snp ./$3/$1.chr$2.duplicate.snp.site.out --output-log ./$3/$1.chr$2.alignments

cat ./$3/$1.chr$2.alignments.snp.strand.exclude ./$3/$1.chr$2.duplicate.snp.site.out > ./$3/$1.chr$2.snps.total.exclude

