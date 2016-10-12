# page-imputation
Pegasus Imputation Workflows for PAGE2

## Workflow
### preprocess input data and make sure they are ready for imputation
* to convert genome position from one build to another
* to convert dbSNP rs number from one build to another
* to rewrite plink \*.bim file when a SNP is monomorphic by comparing to 1000 Genome Project
* to do a QC check before imputation

### extract chromosomes
* to filter out duplicate SNPs, INDELs
* to extract a chromosome for imputation
* to recode data into VCF format

### SHAPEIT phasing
* implement SHAPEIT for haplotypes estimation (phasing)

### imputation
* implememt IMPUTE2 for genotype imputation


