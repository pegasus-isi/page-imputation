#!/bin/bash
#$ -cwd
#$ -j y

CDIR='pwd'

##Date: April 7, 2015
##Created by: Lisheng Zhou
##Version 2 (Changes based on the conference call on April 3, 2015)


##======================== Modify  =================================

num=22
node=chr22 ##node=name of chromosome ##mkdir $node
study=testing
##======================== Modify End ==============================

chr1=248956422
chr2=242193529
chr3=198295559
chr4=190214555
chr5=181538259
chr6=170805979
chr7=159345973
chr8=145138636
chr9=138394717
chr10=133797422
chr11=135086622
chr12=133275309
chr13=114364328
chr14=107043718
chr15=101991189
chr16=90338345
chr17=83257441
chr18=80373285
chr19=58617616
chr20=63025520
chr21=48129895
chr22=51304566

string="chr$num"
size=${!string}

# 1) vcf generated
bash extract_chromosome.sh $study $num $node


# 2) run shapeit phase
bash phase-shapeit.sh $study $num $node

# 5) Impute2
i=1
for ((i=1; i<$size; i=i+5000000))
do
	j=$(($i+4999999))
	if [ $j -gt $size ]
	then
		j=$size
	fi
	echo "$i"
	echo "$j"
	#edited by Lisheng: 11/09/2015
	count=$(awk -v d1="$i" -v d2="$j" '{if (($3 >=d1 )&&($3<=d2)) print $0}' BioMe-AA_ILLUMINA.phase.chr${num}.haps | wc -l)

	if [ $count > 0 ]
	then
		bash impute2.sh $study $num $i $j $node
	fi
	## END 11/09/2015
done

