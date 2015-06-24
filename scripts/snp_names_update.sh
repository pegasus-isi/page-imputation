#! /bin/bash
#$ -j y
#$ -cwd
CDIR='pwd'

## Date:	June 11, 2015
## Created by: 	Lisheng Zhou

# make the script fail on errors
set -e

## Update SNP names to current rsIDs -- new version!!

file=$1
study=$2

## 1. Process a list from dbSNP
## Different from the old version, LiftRsNumber.py is used in this version
awk '{print $2}' $file.bim | grep rs | awk -F"rs" '{print $2}' > old_rs_dbSNP.in
python LiftRsNumber.py old_rs_dbSNP.in > lifted_rs_dbSNP.out
awk '{print "rs"$2}' lifted_rs_dbSNP.out > temp1.out
awk '{print "rs"$0}' old_rs_dbSNP.in > temp2.out
paste -d'\t' temp2.out temp1.out > temp3.out
perl -nle 'unless($hash{$_}++){print $_}' temp3.out > dbSNP_rs_lifted.out ## remove duplicate lines
plink-1.9 --bfile $file --update-map dbSNP_rs_lifted.out --update-name --make-bed --out TEMP1

rm temp* old_rs_dbSNP.in lifted_rs_dbSNP.out 

## 2. Process two lists: HumanCoreExome-24v1-0_A_rsids.txt HumanOmni25Exome-8v1-1_A_rsids.txt
cat HumanCoreExome-24v1-0_A_rsids.txt HumanOmni25Exome-8v1-1_A_rsids.txt | grep Name -v | grep '\.' -v > temp1.out
perl -nle 'unless($hash{$_}++){print $_}' temp1.out > temp2.out
plink-1.9 --bfile TEMP1 --update-map temp2.out --update-name --make-bed --out TEMP2

rm temp*

## 3. Remove duplicate SNPs
## 3a. To remove duplicate reads, remain one of them
sort TEMP2.bim | uniq -d | awk '{print $2}' > temp1.out
plink --bfile TEMP2 --exclude temp1.out --make-bed --out TEMP3
## 3b. To remove those with 3 dupplicates, remain one of them
sort TEMP3.bim | uniq -d | awk '{print $2}' > temp2.out
plink --bfile TEMP3 --exclude temp2.out --make-bed --out TEMP4
## 3c. To remove SNPs with same name but different in ref and alt alleles
awk '{print $2}' TEMP4.bim | sort | uniq -d > temp3.out
plink-1.9 --bfile TEMP4 --exclude temp3.out --make-bed --out $study

rm temp* TEMP*



