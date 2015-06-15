#!/usr/bin/env python


import sys
import os
import optparse
import subprocess


#some constants. can be updated via command line options
DEFAULT_CHROMOSOME_START                 = 1
DEFAULT_CHROMOSOME_END                   = 22
DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG = False #whether intermediate files make it to the output site or not
DEFAULT_REFERENCE_FILE_PREFIX           = "1000GP_Phase3"
DEFAULT_EXCLUDE_SNPS_FILE_LFN           = "snps-to-exclude.txt"

# global constants
DEFAULT_IMPUTATION_CHUNKING_INTERVAL  = 5000000 #based on biological reasons plus the specifics of the program).
IMPUTE_DAGMAN_CATEGORY = "impute2"
PHASE_SHAPEIT_DAGMAN_CATEGORY = "shapeit"

pegasus_config = "pegasus-config --python-dump"
config = subprocess.Popen(pegasus_config, stdout=subprocess.PIPE, shell=True).communicate()[0]
exec config


from Pegasus.DAX3 import *

chromosome_chunk_ends = [
    248956422, #chr 1
    242193529, #chr 2
    198295559, #chr 3
    190214555, #chr 4
    181538259, #chr 5
    170805979, #chr 6
    159345973, #chr 7
    145138636, #chr 8
    138394717, #chr 9
    133797422, #chr 10
    135086622, #chr 11
    133275309, #chr 12
    114364328, #chr 13
    107043718, #chr 14
    101991189, #chr 15
    90338345,  #chr 16
    83257441,  #chr 17
    80373285,  #chr 18
    58617616,  #chr 19
    63025520,  #chr 20
    48129895,  #chr 21
    51304566   #chr 22
]

def getDAX( genotype_file,
            chromosome_start,
            chromosome_end ,
            addon_test_shapeit_args=None,
            addon_phase_shapeit_args=None):
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

        phase_shapeit_job = construct_phase_shapeit_job( prefix, chromosome, reference_file_prefix , snps_to_exclude, addon_phase_shapeit_args)
        dax.addJob( phase_shapeit_job )
        dax.depends( parent=extract_job,child=phase_shapeit_job )

        #figure out the chunk start and end based on chunking end point for chromosome
        chromosome_global_chunk_end =  chromosome_chunk_ends[ chromosome - 1 ]
        for chunk_start in range( 1, chromosome_global_chunk_end, DEFAULT_IMPUTATION_CHUNKING_INTERVAL ):
            chunk_end = chunk_start + DEFAULT_IMPUTATION_CHUNKING_INTERVAL - 1
            if chunk_end >  chromosome_global_chunk_end:
                chunk_end =  chromosome_global_chunk_end

            print "Constructing impute job for chunk interval %s %s" %(chunk_start, chunk_end)
            impute_job = construct_imputation_job( prefix, chromosome, reference_file_prefix, snps_to_exclude, chunk_start, chunk_end )
            dax.addJob( impute_job )
            dax.depends( parent=phase_shapeit_job, child=impute_job )


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

    chromosome_str = str(chromosome_num)
    chromosome_name =  "chr" + chromosome_str

    args = []
    args.append( prefix )
    args.append( chromosome_str )
    args.append( "." )

    genotype_lfn = prefix + ".vcf.gz"
    j.uses(File( genotype_lfn ), link=Link.INPUT)



    #construct the output files
    for suffix in [ ".recode.vcf.gz" , ".recode.vcf.gz.tbi"]:
        output_file = prefix + "." + chromosome_name + suffix
        j.uses( output_file, link=Link.OUTPUT, transfer=DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG)

    duplicate_snp_file = get_duplicate_snp_lfn( prefix, chromosome_num );
    j.uses( File(duplicate_snp_file), link=Link.OUTPUT, transfer=DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG)

    # Include dependant executable
    #j.uses(Executable("R"), link=Link.INPUT)
    
    # Finish job
    j.addArguments(*args)

    return j

def construct_test_shapeit_job( prefix, chromosome_num, reference_file_prefix, snps_exclude_lfn, addon_args):
    """
    This function returns a R job to the workflow that updates the input maps.
    Input File: mec-2010-11-19.map
    Output Files: mec-2010-11-19build37.map mec-2010-11-19.rsIDs.txt
    """
    j = Job(name="test_shapeit")

    chromosome_str = str(chromosome_num)
    chromosome_name =  "chr" + chromosome_str

    args = []
    args.append( prefix )
    args.append( chromosome_str )
    args.append( "." )
    if addon_args is not None:
        args.append( addon_args )

    for suffix in [ ".recode.vcf.gz" ]:
        input_file = prefix + "." + chromosome_name + suffix
        j.uses( input_file , link=Link.INPUT)

    duplicate_snp_file = get_duplicate_snp_lfn( prefix, chromosome_num );
    j.uses( File(duplicate_snp_file), link=Link.INPUT)

    #j.uses( snps_exclude_lfn, link=Link.INPUT)

    #add base reference files
    base_reference_files = get_base_reference_files( reference_file_prefix, chromosome_num )
    for input in base_reference_files :
        j.uses(input , link = Link.INPUT )

    #add the output log files
    for suffix in ["alignments.snp.log", "alignments.snp.strand", "alignments.snp.strand.exclude"]:
        output_file = prefix + "." + chromosome_name + "." + suffix
        j.uses( output_file, link=Link.OUTPUT, transfer=DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG)

    output_file = get_total_snp_exclude_lfn( prefix, chromosome_num )
    j.uses( output_file, link=Link.OUTPUT, transfer=DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG)

    # Include dependant executable
    #j.uses(Executable("R"), link=Link.INPUT)

    # Finish job
    j.addArguments(*args)

    return j

def construct_phase_shapeit_job( prefix, chromosome_num, reference_file_prefix, snps_exclude_lfn, addon_args ):
    """
    This function returns a R job to the workflow that updates the input maps.
    Input File: mec-2010-11-19.map
    Output Files: mec-2010-11-19build37.map mec-2010-11-19.rsIDs.txt
    """
    j = Job(name="phase_shapeit")

    chromosome_str = str(chromosome_num)
    chromosome_name =  "chr" + chromosome_str

    args = []
    args.append( prefix )
    args.append( chromosome_str )
    args.append( "." )
    if addon_args is not None:
        args.append( addon_args )

    for suffix in [ ".recode.vcf.gz" ]:
        input_file = prefix + "." + chromosome_name + suffix
        j.uses( input_file , link=Link.INPUT)

    duplicate_snp_file = get_duplicate_snp_lfn( prefix, chromosome_num );
    j.uses( File(duplicate_snp_file), link=Link.INPUT)
    # was created by test_shapeit job, we use duplicate snp file as input instead
    #total_snps_excluded_file = get_total_snp_exclude_lfn( prefix, chromosome_num )
    #j.uses( total_snps_excluded_file, link=Link.INPUT)

    #add base reference files
    base_reference_files = get_base_reference_files( reference_file_prefix, chromosome_num )
    for input in base_reference_files :
        j.uses(input , link = Link.INPUT )

    genetic_map_combined_lfn = "genetic_map_chr" + chromosome_str + "_combined_b37.txt"
    j.uses( File(genetic_map_combined_lfn), link=Link.INPUT)

    for suffix in [".haps", ".sample", ".snp.mm", ".ind.mm", ".log" ]:
        output_file = prefix + ".phase." + chromosome_name + suffix
        j.uses( output_file, link=Link.OUTPUT, transfer=DEFAULT_INTERMEDIATE_FILES_TRANSFER_FLAG)

    #associate a DAGMAN category for throttling purposes
    j.addProfile( Profile("dagman", "CATEGORY", PHASE_SHAPEIT_DAGMAN_CATEGORY ))

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

    chromosome_str  = str(chromosome_num)
    chromosome_name = "chr" + chromosome_str

    chunk_start = str( int(float(chunk_start)) )
    chunk_end   = str( int(float(chunk_end)) )
    args = []
    args.append( prefix )
    args.append( chromosome_str )
    args.append( "." )
    args.append( chunk_start )
    args.append( chunk_end )

    for suffix in [ ".haps" ]:
        input_file = prefix + ".phase." + chromosome_name + suffix
        j.uses(File( input_file ), link=Link.INPUT)

    #add base reference files
    base_reference_files = get_base_reference_files( reference_file_prefix, chromosome_num )
    for input in base_reference_files :
        j.uses(input , link = Link.INPUT )

    genetic_map_combined_lfn = "genetic_map_chr" + chromosome_str + "_combined_b37.txt"
    j.uses( File(genetic_map_combined_lfn), link=Link.INPUT)

    output_prefix = prefix + "." + chromosome_name + ".pos" + chunk_start + "-" + chunk_end ;
    for suffix in [".impute2_diplotype_ordering" ,".impute2_info" ,".impute2_info_by_sample", ".impute2_summary", ".impute2_warnings"]:
        j.uses( output_prefix + suffix, link=Link.OUTPUT, transfer=True)

    # Include dependant executable
    #j.uses(Executable("R"), link=Link.INPUT)

    # Finish job
    j.addArguments(*args)

    #associate a DAGMAN category for throttling purposes
    j.addProfile( Profile("dagman", "CATEGORY", IMPUTE_DAGMAN_CATEGORY ))


    return j



def get_base_reference_files( prefix, chromosome_num ):
    """
    Constructs the base references files
    """


    chromosome_str = str( chromosome_num )
    files = []
    #construct the input reference files
    for suffix in [ ".legend.gz", ".hap.gz"]:
        input_file = prefix + "_chr" + chromosome_str + suffix
        files.append( input_file )

    files.append( prefix + ".sample")
    return files

def get_duplicate_snp_lfn( prefix, chromosome_num ):
    """
    Returns the lfn for the duplicate snp files
    """

    return  prefix + "." + "chr" + str(chromosome_num) +  ".duplicate.snp.site.out"


def get_total_snp_exclude_lfn( prefix, chromosome_num ):
    """
    Returns the lfn for the total snps to be excluded
    """

    return  prefix + "." + "chr" + str(chromosome_num) +  ".snps.total.exclude"



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

    parser.add_option("-g", "--genotype-file", action="store", type="str", dest="genotype_file",  help="basename of the genotype-file")
    parser.add_option("-s", "--chromosome-start", action="store", type="int", dest="chromosome_start", help="chromosome start index")
    parser.add_option("-e", "--chromosome-end", action="store", type="int", dest="chromosome_end", help="chromosome end index")
    parser.add_option("-o", "--output-dax", action="store", type="str", dest="daxfile", help="the output dax file to write")
    parser.add_option("--test-shapeit-args", action="store", type="str", dest="test_shapeit_args", help="extra arguments to be passed to test shapeit job")
    parser.add_option("--phase-shapeit-args", action="store", type="str", dest="phase_shapeit_args", help="extra arguments to be passed to phase shapeit job")

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
                  options.chromosome_end,
                  options.test_shapeit_args,
                  options.phase_shapeit_args)

    f = open( options.daxfile,"w" )
    print "Writing DAX to %s" %(os.path.abspath( options.daxfile ) )
    dax.writeXML(f)
    f.close()

    # dup the dax to stdout for time being
    dax.writeXML(sys.stdout)

if __name__ == "__main__":
    main()
