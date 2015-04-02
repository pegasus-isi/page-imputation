#!/usr/bin/env python


import sys
import os
import optparse
import subprocess

from Pegasus.DAX3 import *

#some constants. can be updated via command line options
DEFAULT_CHROMOSOME_START                 = 1
DEFAULT_CHROMOSOME_END                   = 22
DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG = False #whether intermediate files make it to the output site or not
DEFAULT_REFERENCE_FILE_PREFIX           = "1000GP_Phase3_"
DEFAULT_EXCLUDE_SNPS_FILE_LFN           = "snps-to-exclude.txt"

pegasus_config = "pegasus-config --python-dump"
config = subprocess.Popen(pegasus_config, stdout=subprocess.PIPE, shell=True).communicate()[0]
exec config


def getDAX( genotype_file,
            chromosome_start,
            chromosome_end ):
    """
    This generates dax for a particular study and a date corresponding to it
    """

    prefix = genotype_file
    dax = ADAG("imputation2-" + prefix )

    reference_file_prefix = DEFAULT_REFERENCE_FILE_PREFIX
    snps_to_exclude       = DEFAULT_EXCLUDE_SNPS_FILE_LFN

    #for each chromsome create an extract job
    for chromosome in range( chromosome_start, chromosome_end + 1 ):
        extract_job = construct_extract_job( prefix, chromosome )
        dax.addJob( extract_job )

        test_shapeit_job = construct_test_shapeit_job( prefix, chromosome, reference_file_prefix, snps_to_exclude )
        dax.addJob( test_shapeit_job )
        dax.depends( parent=extract_job,child=test_shapeit_job )

        phase_shapeit_job = construct_phase_shapeit_job( prefix, chromosome, reference_file_prefix , snps_to_exclude)
        dax.addJob( phase_shapeit_job )
        dax.depends( parent=test_shapeit_job,child=phase_shapeit_job )

        impute_job = construct_imputation_job( prefix, chromosome, reference_file_prefix, snps_to_exclude, 0, 0 )
        dax.addJob( impute_job )
        dax.depends( parent=phase_shapeit_job, child=impute_job )
        dax.depends( parent=test_shapeit_job, child=impute_job )

    # notifcations on state changes for the dax
    dax.invoke("all", pegasus_share_dir + "/notification/email")
    return dax



def construct_extract_job( prefix, chromosome_num ):
    """
    This function returns a R job to the workflow that updates the input maps.
    Input File: mec-2010-11-19.map
    Output Files: mec-2010-11-19build37.map mec-2010-11-19.rsIDs.txt
    """
    j = Job(name="extract_chromosome")

    args = []
    args.append( "--vanilla" )
    args.append( "--args" )

    genotype_lfn = prefix + ".vcf.gz"
    j.uses(File( genotype_lfn ), link=Link.INPUT)

    chromosome_str = str(chromosome_num)

    #construct the output files
    for suffix in [ ".vcf.bgz" ".vcf.bgz.tbi"]:
        output_file = prefix + "-" + chromosome_str + suffix
        j.uses( output_file, link=Link.OUTPUT, transfer=DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG)

    # Include dependant executable
    #j.uses(Executable("R"), link=Link.INPUT)
    
    # Finish job
    j.addArguments(*args)

    return j

def construct_test_shapeit_job( prefix, chromosome_num, reference_file_prefix, snps_exclude_lfn ):
    """
    This function returns a R job to the workflow that updates the input maps.
    Input File: mec-2010-11-19.map
    Output Files: mec-2010-11-19build37.map mec-2010-11-19.rsIDs.txt
    """
    j = Job(name="test-shapeit")

    chromosome_str = str(chromosome_num)

    args = []
    args.append( "--vanilla" )
    args.append( "--args" )

    for suffix in [ ".vcf.bgz" ]:
        input_file = prefix + "-" + chromosome_str + suffix
        j.uses(File( input_file ), link=Link.INPUT)

    j.uses( File(snps_exclude_lfn), link=Link.INPUT)

    #construct the input reference files files
    for suffix in [ "legend.gz" ".hap.gz"]:
        input_file = reference_file_prefix + chromosome_str + suffix
        j.uses(File( input_file ), link=Link.INPUT)

    reference_sample_file = File( reference_file_prefix + ".sample")
    j.uses( File(reference_sample_file), link=Link.INPUT)

    output_file = prefix + "-" + chromosome_str + "-" + "duplicate-snp-site.txt"
    j.uses( output_file, link=Link.OUTPUT, transfer=DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG)

    # Include dependant executable
    #j.uses(Executable("R"), link=Link.INPUT)

    # Finish job
    j.addArguments(*args)

    return j

def construct_phase_shapeit_job( prefix, chromosome_num, reference_file_prefix, snps_exclude_lfn ):
    """
    This function returns a R job to the workflow that updates the input maps.
    Input File: mec-2010-11-19.map
    Output Files: mec-2010-11-19build37.map mec-2010-11-19.rsIDs.txt
    """
    j = Job(name="phase-shapeit")

    chromosome_str = str(chromosome_num)

    args = []
    args.append( "--vanilla" )
    args.append( "--args" )

    for suffix in [ ".vcf.bgz" ]:
        input_file = prefix + "-" + chromosome_str + suffix
        j.uses(File( input_file ), link=Link.INPUT)

    j.uses( File(snps_exclude_lfn), link=Link.INPUT)
    duplicate_snp_lfn = prefix + "-" + chromosome_str + "-" + "duplicate-snp-site.txt"
    j.uses( File(duplicate_snp_lfn), link=Link.INPUT)

    #construct the input reference files files
    for suffix in [ "legend.gz" ".hap.gz"]:
        input_file = reference_file_prefix + chromosome_str + suffix
        j.uses(File( input_file ), link=Link.INPUT)

    reference_sample_lfn = File( reference_file_prefix + ".sample")
    j.uses( File(reference_sample_lfn), link=Link.INPUT)

    genetic_map_combined_lfn = "genetic_map_chr" + chromosome_str + "_combined_b37.txt"
    j.uses( File(genetic_map_combined_lfn), link=Link.INPUT)

    for suffix in [".haps", ".sample" ]:
        output_file = prefix + "-" + chromosome_str + suffix
        j.uses( output_file, link=Link.OUTPUT, transfer=DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG)

    # Include dependant executable
    #j.uses(Executable("R"), link=Link.INPUT)

    # Finish job
    j.addArguments(*args)

    return j

def construct_imputation_job( prefix, chromosome_num, reference_file_prefix, snps_exclude_lfn, chunk_start, chunk_end ):
    """
    This function returns a R job to the workflow that updates the input maps.
    Input File: mec-2010-11-19.map
    Output Files: mec-2010-11-19build37.map mec-2010-11-19.rsIDs.txt
    """
    j = Job(name="impute2")
    chromosome_str = str(chromosome_num)

    args = []
    args.append( "--vanilla" )
    args.append( "--args" )

    for suffix in [ ".haps" ]:
        input_file = prefix + "-" + chromosome_str + suffix
        j.uses(File( input_file ), link=Link.INPUT)

    j.uses( File(snps_exclude_lfn), link=Link.INPUT)
    duplicate_snp_lfn = prefix + "-" + chromosome_str + "-" + "duplicate-snp-site.txt"
    j.uses( File(duplicate_snp_lfn), link=Link.INPUT)

    #construct the input reference files files
    for suffix in [ "legend.gz" ".hap.gz"]:
        input_file = reference_file_prefix + chromosome_str + suffix
        j.uses(File( input_file ), link=Link.INPUT)


    genetic_map_combined_lfn = "genetic_map_chr" + chromosome_str + "_combined_b37.txt"
    j.uses( File(genetic_map_combined_lfn), link=Link.INPUT)

    for output_file in ["impute2_diplotype_ordering" "impute_info" "impute2_info_by_sample" "impute2_summary" "impute2_warnings"]:
        j.uses( output_file, link=Link.OUTPUT, transfer=DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG)

    # Include dependant executable
    #j.uses(Executable("R"), link=Link.INPUT)

    # Finish job
    j.addArguments(*args)

    return j


def getLFNAndAddToDAX( dax, file ):
    """
    Helper method that derives the LFN from the basename of the file and also adds
    to the DAX to be tracked
    """

    lfn = os.path.basename( file );
    #if the file specified is an actual file
    if os.path.isfile( file ):
        file = os.path.abspath( file )
        # Add input file to the DAX-level replica catalog
        f = File( lfn )
        f.addPFN( PFN("file://" + file, "local") )
        dax.addFile( f )


    return lfn



def get_erate_file_lfn( chromosome_num ):
    """
    Returns the lfn for the erate file based on the chromosome passed
    """

    return "chr" + str(chromosome_num) +  ".erate"


def get_rec_file_lfn( chromosome_num ):
    """
    Returns the lfn for the rec file based on the chromosome passed
    """

    return "chr" + str(chromosome_num) +  ".rec"


def main():
    # Configure command line option parser
    usage = '%s [options]' % sys.argv[0]
    description = '%s [gseo]'    % sys.argv[0]

    parser = optparse.OptionParser (usage=usage, description=description)

    parser.add_option ("-g", "--genotype-file", action="store", type="str", dest="genotype_file",  help="basename of the genotype-file")
    parser.add_option ("-s", "--chromosome-start", action="store", type="int", dest="chromosome_start", help="chromosome start index")
    parser.add_option ("-e", "--chromosome-end", action="store", type="int", dest="chromosome_end", help="chromosome end index")
    parser.add_option ("-o", "--output-dax", action="store", type="str", dest="daxfile", help="the output dax file to write")

    #Parsing command-line options
    (options, args) = parser.parse_args ()

    if options.genotype_file is None:
        parser.error( "Specify the -g option to specify genotype filename")

    if options.chromosome_start is None:
        print "Using default value for chromosome start"
        options.chromosome_start = DEFAULT_CHROMOSOME_START

    if options.chromosome_end is None:
        print "Using default value for chromosome end"
        options.chromosome_end = DEFAULT_CHROMOSOME_END


    if options.daxfile is None:
        parser.error( "Specify the -o option to specify the output dax file ")

    dax = getDAX( options.genotype_file,
                  options.chromosome_start,
                  options.chromosome_end)

    f = open( options.daxfile,"w" )
    print "Writing DAX to %s" %(os.path.abspath( options.daxfile ) )
    dax.writeXML(f)
    f.close()

    # dup the dax to stdout for time being
    dax.writeXML(sys.stdout)

if __name__ == "__main__":
    main()
