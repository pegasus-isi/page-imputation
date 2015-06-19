#! /bin/bash
#$ -j y
#$ -cwd
CDIR='pwd'

file="BioMe-AA_ILLUMINA"
study="chr22"

echo "SNP names update"
## bash snp_names_update.sh input_prefix output
bash snp_names_update.sh $file ${study}-result

echo "monomorphic SNPs"
Rscript --vanilla more-alleles-2015-05-25.R ALL.chr22.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz ${study}-result ${study}-result2

echo "liftOver"
bash liftover_to_37.sh ${study}-result2


echo "HRC process step"
perl HRC-check-bim.pl ${study}-result2-final.bim

echo "HRC 2nd step"
bash Run-plink.sh
rm *-${study}-result2-final.bim
## generate xxx-updated.bim

echo "convert into VCF"
mkdir $study
mv ${study}-result2-final-updated* $study/
cd $study
plink-1.9 --bfile ${study}-result2-final-updated --recode vcf --out $file
gzip $file.vcf
cd ..

