#!/bin/bash

set -e

TOPDIR=`pwd`

# the path that is set for jobs running on operon
CLUSTER_PATH="/home/nfs/bin:/usr/local/SGE/bin:/usr/local/SGE/bin/lx-amd64:/usr/local/condor/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

# pegasus bin directory is needed to find keg
BIN_DIR=`pegasus-config --bin`

JOB_CLUSTERS_SIZE=2
LOCAL_SGE_PEGASUS_HOME=`dirname $BIN_DIR`

mkdir -p conf

# create the site catalog
echo "Creating the site catalog $TOPDIR/conf/sites.xml "
cat >conf/sites.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<sitecatalog xmlns="http://pegasus.isi.edu/schema/sitecatalog" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pegasus.isi.edu/schema/sitecatalog http://pegasus.isi.edu/schema/sc-4.0.xsd" version="4.0">
    
    <!-- The local site contains information about the submit host -->
    <!-- The arch and os keywords are used to match binaries in the transformation catalog -->
    <site  handle="local" arch="x86_64" os="LINUX">
        <directory type="shared-scratch" path="$TOPDIR/work">
            <file-server operation="all" url="file://$TOPDIR/work"/>
        </directory>
        <directory type="local-storage" path="$TOPDIR/outputs">
            <file-server operation="all" url="file://$TOPDIR/outputs"/>
        </directory>
    </site>

    <!-- the operon2 cluster designates the Rutgers Operon cluster -->
    <site  handle="operon" arch="x86_64" os="LINUX" osrelease="deb" osversion="8">
        <!--shared scratch directory indicates a directory that is visible
            on all the nodes of the OPERON cluster. This is where the jobs
            execute -->
        <directory type="shared-scratch" path="$TOPDIR/OPERON/shared-scratch">
            <file-server operation="all" url="file://$TOPDIR/OPERON/shared-scratch"/>
        </directory>

        <!-- tell pegasus it is a SGE cluster and submission to be via glite -->
        <profile namespace="pegasus" key="style" >glite</profile>
        <profile namespace="condor" key="grid_resource">sge</profile>

        <profile namespace="env" key="PEGASUS_HOME">$LOCAL_SGE_PEGASUS_HOME</profile>
        <profile namespace="pegasus" key="change.dir">true</profile>
        <profile namespace="env" key="PATH">$TOPDIR/scripts:${CLUSTER_PATH}</profile>

    </site>

</sitecatalog>
EOF

# create the transformation catalog (tc)
echo
echo "Creating the transformation catalog $TOPDIR/conf/tc.text "

cat >conf/tc.text <<EOF
# This is the transformation catalog. It lists information about each of the
# executables that are used by the workflow.

EOF

# transformation names and matching executables
transformations=( preprocessing#run_preprocessing.sh extract_chromosome#extract_chromosome.sh phase_shapeit#phase-shapeit.sh impute2#impute2.sh )

for MAPPING in "${transformations[@]}"; do 
    TRANSFORMATION=`echo $MAPPING | sed -E "s/(.*)#.*/\1/g"`
    SCRIPT=`echo $MAPPING | sed -E "s/.*#(.*)/\1/g"`
    cat >>conf/tc.text <<EOF
tr $TRANSFORMATION{
    site operon {
        pfn "${TOPDIR}/scripts/$SCRIPT"
        arch "x86_64"
        os "LINUX"
        osrelease "deb"
        osversion "8"
        type "INSTALLED"        
    }
}
EOF
done
