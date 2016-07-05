### R script to rewrite plink *.bim file when a SNP is monomorphic by comparing to 1KGP

# Outputs  binary file fewer SNPs showing no minor allele

# Example calls:
# Rscript --vanilla more-alleles-2015-04-27.R reffile input.prefix  output.prefix
# Rscript --vanilla more-alleles-2015-04-27.R ALL.chr22.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz testing.chr22 result


args <- commandArgs(trailingOnly = TRUE)

reffile <- args[1]  ### assuming this is *.vcf.gz format
input.prefix <- args[2]
output.prefix <- args[3]

temp.filename1 <- paste(output.prefix, "temp1.txt", sep = "-")
temp.filename2 <- paste(output.prefix, "temp2.txt", sep = "-")

rev.strand <- function(x) c("T", "G", "C", "A")[match(x, c("A", "C", "G", "T"))]

### changed to zcat from gzcat
system(paste("zcat", reffile, "| cut -f1-5 > ", temp.filename1))
ref.alleles <- read.table(temp.filename1, header = FALSE, as.is = TRUE)
names(ref.alleles) <- c("CHROM", "POS", "ID", "REF", "ALT")

production.alleles <- read.table(paste(input.prefix, ".bim", sep = ""), header = FALSE, as.is = TRUE)
names(production.alleles) <- c("CHROM", "ID", "cM", "POS", "A1", "A2")

problem.alleles <- production.alleles[with(production.alleles, A1 == "0" | A2 == "0"),]
problem.alleles <- merge(problem.alleles, ref.alleles, by = "ID")

problem.alleles <- problem.alleles[with(problem.alleles, nchar(REF) == 1 & nchar(ALT) == 1),] # Drop non biallelic variants and non-SNPs

# Just need a file for plink step in case there are no problem alleles
system(paste("touch", temp.filename2))

if (nrow(problem.alleles) > 0){ 
	problem.alleles$newA1 <- NA
	problem.alleles$newA2 <- NA

	problem.alleles$newA2[problem.alleles$A2 == problem.alleles$REF] <- problem.alleles$REF[problem.alleles$A2 == problem.alleles$REF]
	problem.alleles$newA1[problem.alleles$A2 == problem.alleles$REF] <- problem.alleles$ALT[problem.alleles$A2 == problem.alleles$REF]

	problem.alleles$newA2[problem.alleles$A2 == rev.strand(problem.alleles$REF)] <- rev.strand(problem.alleles$REF[problem.alleles$A2 == rev.strand(problem.alleles$REF)])
	problem.alleles$newA1[problem.alleles$A2 == rev.strand(problem.alleles$REF)] <- rev.strand(problem.alleles$ALT[problem.alleles$A2 == rev.strand(problem.alleles$REF)])

#	write.table(problem.alleles[, c("ID", "A1", "A2", "newA1", "newA2")], file = temp.filename2, col.names = FALSE, row.names = FALSE, quote = FALSE)
	write.table(na.omit(problem.alleles[, c("ID", "A1", "A2", "newA1", "newA2")]), file = temp.filename2, col.names = FALSE, row.names = FALSE, quote = FALSE) 
}
system("PLINK_MEMORY=8192")
system("export PLINK_MEMORY")
system(paste("plink --memory ${PLINK_MEMORY} --bfile", input.prefix, "--update-alleles", temp.filename2, "--make-bed --out", output.prefix))

## Clean up
#system(paste("rm ", temp.filename1, temp.filename2))
