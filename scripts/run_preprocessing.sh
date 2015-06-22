#! /bin/bash
#$ -j y
#$ -cwd
CDIR='pwd'

file="BioMe-AA_ILLUMINA"
num=22
study="testing"
node="chr22"

echo "SNP names update"
## bash snp_names_update.sh input_prefix output
bash snp_names_update.sh $file ${study}-${num}-result

echo "monomorphic SNPs"
Rscript --vanilla more-alleles-2015-05-25.R ALL.chr${num}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz ${study}-${num}-result ${study}-${num}-result2

echo "liftOver"
bash liftover_to_37.sh ${study}-${num}-result2


echo "HRC process step"
perl HRC-check-bim.pl ${study}-${num}-result2-final.bim

echo "HRC 2nd step"
bash Run-plink.sh
rm *-${study}-${num}-result2-final.bim
## generate xxx-updated.bim

echo "convert into VCF"
mkdir $study-${num}
mv ${study}-${num}-result2-final-updated* $study-${num}/
cd $study-${num}
plink-1.9 --bfile ${study}-${num}-result2-final-updated --recode vcf --out $study.$num
gzip $study.$num.vcf
cd ..

