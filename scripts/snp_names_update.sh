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
awk '{print $2}' $file.bim | grep rs | awk -F"rs" '{print $2}' > ${study}.old_rs_dbSNP.in
LiftRsNumber.py ${study}.old_rs_dbSNP.in > ${study}.lifted_rs_dbSNP.out
awk '{print "rs"$2}' ${study}.lifted_rs_dbSNP.out > ${study}.temp1.out
awk '{print "rs"$0}' ${study}.old_rs_dbSNP.in > ${study}.temp2.out
paste -d'\t' ${study}.temp2.out ${study}.temp1.out > ${study}.temp3.out
perl -nle 'unless($hash{$_}++){print $_}' ${study}.temp3.out > ${study}.dbSNP_rs_lifted.out ## remove duplicate lines
plink --bfile $file --update-map ${study}.dbSNP_rs_lifted.out --update-name --make-bed --out ${study}.TEMP1

rm ${study}.temp* ${study}.old_rs_dbSNP.in ${study}.lifted_rs_dbSNP.out 

## 2. Process two lists: HumanCoreExome-24v1-0_A_rsids.txt HumanOmni25Exome-8v1-1_A_rsids.txt
cat HumanCoreExome-24v1-0_A_rsids.txt HumanOmni25Exome-8v1-1_A_rsids.txt | grep Name -v | grep '\.' -v > ${study}.temp1.out
perl -nle 'unless($hash{$_}++){print $_}' ${study}.temp1.out > ${study}.temp2.out
plink --bfile ${study}.TEMP1 --update-map ${study}.temp2.out --update-name --make-bed --out ${study}.TEMP2

rm ${study}.temp*

## 3. Remove duplicate SNPs
## 3a. To remove duplicate reads, remain one of them
sort ${study}.TEMP2.bim | uniq -d | awk '{print $2}' > ${study}.temp1.out
plink --bfile ${study}.TEMP2 --exclude ${study}.temp1.out --make-bed --out ${study}.TEMP3
## 3b. To remove those with 3 dupplicates, remain one of them
sort ${study}.TEMP3.bim | uniq -d | awk '{print $2}' > ${study}.temp2.out
plink --bfile ${study}.TEMP3 --exclude ${study}.temp2.out --make-bed --out ${study}.TEMP4
## 3c. To remove SNPs with same name but different in ref and alt alleles
awk '{print $2}' ${study}.TEMP4.bim | sort | uniq -d > ${study}.temp3.out
plink --bfile ${study}.TEMP4 --exclude ${study}.temp3.out --make-bed --out $study

rm ${study}.temp* ${study}.TEMP*



