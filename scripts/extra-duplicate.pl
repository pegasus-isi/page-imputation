#!/usr/bin/perl -w
use strict;

##Date: Feb 6, 2015
##Created by: Lisheng Zhou
##Extract the duplicate SNP position from a vcf file
##INPUT: vcf file name to extract from 

if (scalar(@ARGV) != 1){
	die "Usage: $0 <VCF FILENAME>\n";
}

my $infile = $ARGV[0];
#my $outfile = "duplicate.snp.site.out";

#open (OUTFILE, ">$outfile");
open (INFILE, "<$infile") || die "Cannot open vcf file $infile!\n";

my $pos = "idk";
while (my $line = <INFILE>){
	if ($line !~ /^#/){
		chomp $line;
		my @array = split(/\t/, $line);
		if ($array[1] =~ /^$pos$/){
			print "$array[1]\n";
		}else{
			$pos = $array[1];
		}
	}
}
close(INFILE);
#close(OUTFILE);

