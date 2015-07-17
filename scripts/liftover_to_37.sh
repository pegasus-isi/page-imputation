#! /bin/bash
#$ -j y
#$ -cwd
CDIR='pwd'
set -e
## Convert build to 37 via liftOver
## Date: May 12, 2015
## Created by: Lisheng Zhou

## 1. map2bed: convert the bim file into a bed file that liftOver can use
awk '{print "chr"$1"\t"($4-1)"\t"$4"\t"$2}' $1.bim > $1.liftOver.bed

## 2. liftBed: liftOver the bed file into build 37
liftOver $1.liftOver.bed hg38ToHg19.over.chain.gz $1.liftOverout.bed $1.liftOverout.unlifted

## 3. bed2map: Convert the bed file into plink bim file
awk -F'chr' '{print $2}' $1.liftOverout.bed | awk '{print $1"\t"$4"\t0\t"$3}' > $1.liftOverout.new.bim

## 4. update ped file: update the plink file set
awk -F'\t' '{print $4}' $1.liftOverout.unlifted | grep -v '^$' > $1.snpExcludeList.txt
awk 'FNR==NR{a[$2];next}($2 in a){print}' $1.liftOverout.new.bim $1.bim | awk -F'\t' '{print $5"\t"$6}' > $1.attach2bim.out
paste $1.liftOverout.new.bim $1.attach2bim.out > $1.lifted.bim
grep X $1.lifted.bim | awk '{print $2}' >> $1.snpExcludeList.txt
grep Y $1.lifted.bim | awk '{print $2}' >> $1.snpExcludeList.txt
grep _gl $1.lifted.bim | awk '{print $2}' >> $1.snpExcludeList.txt
sed -i '/X/d' $1.lifted.bim
sed -i '/Y/d' $1.lifted.bim
sed -i '/_gl/d' $1.lifted.bim
touch $1-liftedfiles.nof

plink --memory ${PLINK_MEMORY} --bfile $1 --exclude $1.snpExcludeList.txt --recode --out $1-liftedfiles
awk '{print $1"\t"$2"\t"$3"\t"$4}' $1.lifted.bim > $1-liftedfiles.map
#plink-1.9 --file $1-liftedfiles --out $1-FinalVCF --recode vcf ## to match the R script
plink --memory ${PLINK_MEMORY} --file $1-liftedfiles --out $1-final --make-bed

#gzip $1-FinalVCF.vcf

## 5. remove unnecessary files
rm $1.liftOver.bed $1.liftOverout.bed $1.liftOverout.unlifted
rm $1.liftOverout.new.bim $1.snpExcludeList.txt
rm $1.attach2bim.out
rm $1.lifted.bim $1-liftedfiles.log $1-liftedfiles.map $1-liftedfiles.nof $1-liftedfiles.ped
