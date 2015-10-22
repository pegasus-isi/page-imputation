#!/usr/bin/env perl
#
# Script to check plink .bim files against HRC for strand, id names, positions, alleles, ref/alt assignment
# W.Rayner 2014 wrayner@well.ox.ac.uk
# Version 1

# NOTES:
# Script assumes release 1 of the HRC filename HRC.r1.GRCh37.autosomes.mac5.sites.tab, change on line 23 if this is not the case
# in r1 there are only autosomes, so 1-22 only considered by script, others counted in altchr
# Also no indels in r1, so the code for these is not developed, beyond counting them in the bim file
# ARGV[0] should be given as the bim file under consideration
# Script needs ~20Gb RAM to run
# 
#
#
#
#
#

use strict;
use warnings;
$| = 1;

# Set this to the hrc file name
my $hrc_file = 'HRC.r1.GRCh37.autosomes.mac5.sites.tab';

my %id;
my %refalt;
my %rs;
my $indel = 0;
my $mismatchpos = 0;
my $nomatch = 0;
my $unchanged = 0;
my $strand = 0;
my $nostrand = 0;
my $nomatchalleles = 0;
my $idmismatch = 0;
my $idmatch = 0;
my $nothing = 0;
my $idallelemismatch = 0;
my $hrcdot = 0;
my $total = 0;
my $altchr = 0;

open IN, "$hrc_file" or die $!;
while (<IN>)
 {
 chomp;
 if (!/\#.*/)
  {
  if ($. % 100000 == 0)
   {
   print "$.\b\b\b\b\b\b\b\b";
   }
  my @temp = split/\s+/;
  my $chrpos = $temp[0].'-'.$temp[1];
  $id{$chrpos} = $temp[2];
  $rs{$temp[2]} = $chrpos;
  $refalt{$chrpos} = $temp[3].':'.$temp[4];
  }
 }
print "\n";

close IN;

open IN, "$ARGV[0]" or die $!;

#open all the output files for the different plink update lists
my $forcefile = 'Force-Allele1-'.$ARGV[0];
open F, ">$forcefile" or die $!;

my $strandfile = 'Strand-Flip-'.$ARGV[0];
open S, ">$strandfile" or die $!;

open L, ">Log-$ARGV[0]" or die $!;

my $idfile = 'ID-'.$ARGV[0];
open I, ">$idfile" or die $!;

my $posfile = 'Position-'.$ARGV[0];
open P, ">$posfile" or die $!;

my $chrfile = 'Chromosome-'.$ARGV[0];
open C, ">$chrfile" or die $!;

my $excludefile = 'Exclude-'.$ARGV[0]; 
open E, ">$excludefile" or die $!;

# shell script for running plink
my $lisheng_plinkfile = $ARGV[0].'-Run-plink.sh';
open SH, ">$lisheng_plinkfile" or die $!;
#set plink to use here
my $plink = 'plink';

$ARGV[0] =~ /(.*)\.bim$/;
my $file_stem = $1;
my $tempcount = 1;
my $tempfile = $ARGV[0].'.TEMP'.$tempcount;
# make sure fall into error -- Lisheng
print SH "set -e\n";
#remove SNPs
print SH "PLINK_MEMORY=8192\n";
print SH "export PLINK_MEMORY\n";
print SH "$plink --memory \${PLINK_MEMORY} --bfile $file_stem --exclude $excludefile --make-bed --out $tempfile\n";

#change chromosome
print SH "$plink --memory \${PLINK_MEMORY} --bfile $tempfile --update-map $chrfile --update-chr --make-bed --out ";
$tempcount++;
$tempfile = $ARGV[0].'.TEMP'.$tempcount;
print SH "$tempfile\n";

#change positions
print SH "$plink --memory \${PLINK_MEMORY} --bfile $tempfile --update-map $posfile --make-bed --out ";
$tempcount++;
$tempfile = $ARGV[0].'.TEMP'.$tempcount;
print SH "$tempfile\n";

#flip strand
print SH "$plink --memory \${PLINK_MEMORY} --bfile $tempfile --flip $strandfile --make-bed --out ";
$tempcount++;
$tempfile = $ARGV[0].'.TEMP'.$tempcount;
print SH "$tempfile\n";

#force alleles
my $newfile = $file_stem.'-updated';
print SH "$plink --memory \${PLINK_MEMORY} --bfile $tempfile --reference-allele $forcefile --make-bed --out $newfile\n";

#split into per chromosome files
#for (my $i = 1; $i <= 22; $i++)
# {
# my $perchrfile = $newfile.'-chr'.$i;
# print SH "$plink --bfile $newfile --reference-allele $forcefile --make-bed --chr $i --out $perchrfile\n";
# }
print SH "rm $ARGV[0].TEMP*\n";

while (<IN>)
 {
 chomp;
 my $indelflag = 0;
 $total++;
 
 #split line
 my @temp = split/\s+/;
 if ($temp[0] <= 22) # no X, Y, XY or MT in release 1 so skip checking these for now
  {
  #set chr-position id for checks 
  my $chrpos = $temp[0].'-'.$temp[3];
  
  #set alleles for strand and ref/alt checks
  my $bim_alleles = $temp[4].':'.$temp[5];
 
  # if indel, adjust position by -1 before checking
  if ($temp[4] eq '-' or $temp[5] eq '-' or $temp[4] eq 'I' or $temp[5] eq 'I' or $temp[4] eq 'D' or $temp[5] eq 'D')
   {
   $temp[3] = $temp[3] - 1;
   $indel++;
   $indelflag = 1;
   }
  # no indels in r1 of HRC so skip rest for now, indels will flag up at the same pos/different alleles stage 
  # due to the way Illumina represent as -/A but in 1000G represented as T/TA
  
  if ($id{$chrpos}) # position Match
   {
   my $idmismatching = 0;
   if ($id{$chrpos} eq  $temp[1]) # id match
    {
    $idmatch++;
    }
   else # positions the same but ids are not, write to ID file to use as plink update
    {
    $idmismatch++;
    print I "$temp[1]\t$id{$chrpos}\n"; #update ID????
    print L "$temp[1]\t$id{$chrpos}\t$chrpos\t$bim_alleles\t$refalt{$chrpos}\n";
    $idmismatching = 1;
    }
    
   my $checking = check_strand($refalt{$chrpos}, $bim_alleles, $temp[1]);
   if (!$checking)
    {
    if ($idmismatching)
     {
     #alleles and ids don't match
     $idallelemismatch++;
     if ($id{$chrpos} eq '.')
      {
      $hrcdot++;
      }
     }
    #print "nomatch $temp[1]\t$id{$chrpos}\t$refalt{$chrpos}\t$bim_alleles\n";
    print L "nomatch $temp[1]\t$id{$chrpos}\t$refalt{$chrpos}\t$bim_alleles\n";
    $nomatchalleles++;   
   
    #print to an exclusion file
    print E "$temp[1]\n";
    }
   }
  elsif ($rs{$temp[1]}) #match on id, check why position did not match, set position to reference
   {
   #print P "$temp[1]\t$rs{$temp[1]}\n";
   #print P "$temp[1]\t$temp[0]\t$temp[3]\t$rs{$temp[1]}\t$bimalleles\n";
   my @ChrPosRef = split(/-/, $rs{$temp[1]});
   print C "$temp[1]\t$ChrPosRef[0]\n"; #print element [0] chromosome
   print P "$temp[1]\t$ChrPosRef[1]\n"; #print element [1] position
  
   $mismatchpos++;
   my $checking = check_strand($refalt{$rs{$temp[1]}}, $bim_alleles, $temp[1]);
   if (!$checking)
    {
    print L "nomatch $temp[1]\t$id{$rs{$temp[1]}}\t$refalt{$rs{$temp[1]}}\t$bim_alleles\n";
    $nomatchalleles++;   
   
    #print to an exclusion file
    print E "$temp[1]\n";
    }
   }
  else # no match on position or variant id, check +/- 1???
   {
   $nothing++;
   print L "Not in HRC\t$temp[1]\n";
   }
  } #end of Chromosome check section
 else
  {# total all the skipped lines here
  $altchr++;
  }
 }
 
#print "Total bim File Rows $total\n";

my $check_total = $idmatch + $idmismatch + $mismatchpos + $nothing + $altchr ;
my $check_total1 = $unchanged + $nomatch;
my $pos_check = $idmatch + $idmismatch;
my $worked_check = $idmatch + $idmismatch + $mismatchpos;
my $worked_check1 = $strand + $nostrand;

print "\nPosition Matches\n ID matches HRC $idmatch\n ID Doesn't match HRC $idmismatch\n Total Position Matches $pos_check\nID Match\n Different position to HRC $mismatchpos\nNo Match to HRC $nothing\nSkipped (X, XY, Y, MT) $altchr\nTotal in bim file $total\nTotal processed $check_total\n\n"; 
print "Indels (ignored in r1) $indel\n\n";
print "SNPs not changed $unchanged\nSNPs to change ref alt $nomatch\nStrand ok $strand\nTotal Strand ok $check_total1\n\n";
print "Strand to change $nostrand\nTotal checked $worked_check\nTotal checked Strand $worked_check1\n\nNon Matching alleles $nomatchalleles\n";
print "ID and allele mismatching $idallelemismatch; where hrc is . $hrcdot\n";

#print L "Total bim File Rows $total\n";
print L "\nPosition Matches\n ID matches HRC $idmatch\n ID Doesn't match HRC $idmismatch\n Total Position Matches $pos_check\nID Match\n Different position to HRC $mismatchpos\nNo Match to HRC $nothing\nSkipped (X, XY, Y, MT) $altchr\nTotal in bim file $total\nTotal processed $check_total\n\n";  
print L "Indels (ignored in r1) $indel\n\n";
print L "SNPs not changed $unchanged\nSNPs to change ref alt $nomatch\nStrand ok $strand\nTotal Strand ok $check_total1\n\n";
print L "Strand to change $nostrand\nTotal checked $worked_check\nTotal checked Strand $worked_check1\n\nNon Matching alleles $nomatchalleles\n";
print L "ID and allele mismatching $idallelemismatch; where hrc is . $hrcdot\n";

sub check_strand($$$)
 {
 my $check = 0;
 my $a1 = $_[0];
 my $a2 = $_[1];
 my $id = $_[2];
 
 my @alleles1 = split(/\:/, $a1);
 my @alleles2 = split(/\:/, $a2);
 #set the ref allele
 my $ref = $alleles1[0];
 
 print L "$id\t$a1\t$a2";
 # flip one set and check if they match opposite strand
 $a2 =~ tr/ACGT/TGCA/;
 print L "\t$a2\n";
 my @allelesflip = split(/\:/, $a2); 
 
 # check alleles are the same
 if ($alleles1[0] eq $alleles2[0] and $alleles1[1] eq $alleles2[1])
  { # strand ok, ref/alt ok
  $check = 1;
  $strand++;
  $unchanged++;
  }
 elsif ($alleles1[0] eq $alleles2[1] and $alleles1[1] eq $alleles2[0])
  { # strand ok, ref alt swapped
  $check = 2;
  $strand++;
  $nomatch++;
  print F "$id\t$ref\n";
  }
 elsif ($alleles1[0] eq $allelesflip[0] and $alleles1[1] eq $allelesflip[1])
  { # strand flipped, ref alt ok
  $check = 3;
  $nostrand++;
  print S "$id\n";
  }
 elsif ($alleles1[0] eq $allelesflip[1] and $alleles1[1] eq $allelesflip[0])
  { # strand flipped, ref alt swapped
  $check = 4;
  $nostrand++;
  $nomatch++;
  print S "$id\n";
  print F "$id\t$ref\n"; 
  }

 return $check;
 } 
 
