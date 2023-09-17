#!/usr/bin/bash

set -e

#######################################################
####                 PATH CONVENTION               #### 
#######################################################

FASTQS_DIR="01_RawData"
CONCATS_DIR="02_ConcatData"
RESULTS_DIR="03_Projects"
BAMS_DIR="04_BamData"

BACKUP_PWD="/mnt/glustergv0/U981/NIKOLAEV/${USER^^}"
SCRATCH_PWD="/mnt/beegfs/scratch/${USER}"

BACKUP_FASTQ_PWD="${BACKUP_PWD}/${FASTQS_DIR}"
BACKUP_CONCAT_PWD="${BACKUP_PWD}/${CONCATS_DIR}"
BACKUP_RESULTS_PWD="${BACKUP_PWD}/${RESULTS_DIR}"
BACKUP_BAM_PWD="${BACKUP_PWD}/${BAMS_DIR}"

SCRATCH_FASTQ_PWD="${SCRATCH_PWD}/${FASTQS_DIR}"
SCRATCH_CONCAT_PWD="${SCRATCH_PWD}/${CONCATS_DIR}"
SCRATCH_RESULTS_PWD="${SCRATCH_PWD}/${RESULTS_DIR}"
SCRATCH_BAM_PWD="${SCRATCH_PWD}/${BAMS_DIR}"

#### #### #### #### #### #### #### #### ####
####       default global variables     ####
#### #### #### #### #### #### #### #### ####

#### samples: [human|mouse], default: human
#### seq type: [WGS|WES], default: WGS
#### mode: [TvN|TvNp|Tp|T], default: TvN

SAMPLES="human"
SEQ_TYPE="WGS"
MODE="TvN"

#### variant call table
# VAR_TABLE="variant_call_list_${MODE}.tsv"
VAR_TABLE="/mnt/beegfs/scratch/j_wang/03_Projects/19_XPCtox/20230913_Human_WGS_batch_x19_HePG2_XPC_KO/variant_call_list_TvN.tsv"

#### project name: [01_BCC|04_XP_SKIN|05_XP_INTERNAL|17_UV_MMR|19_XPCtox|20_POLZ|21_DEN|23_|....]
PROJECT_NAME="19_XPCtox"

BATCH_POSTFIX="x19_HePG2_XPC_KO"

TODAY=`date +%Y%m%d`
START_DATE=$TODAY
BACKUP_DATE=$TODAY

#### analysis results directory: 
RESULT_BATCH_NAME="${START_DATE}_${SAMPLES}_${SEQ_TYPE}_${MODE}"

if [ $BATCH_POSTFIX != "" ] ; then
    RESULT_BATCH_NAME="${RESULT_BATCH_NAME}_batch_${BATCH_POSTFIX}"
fi

#### raw data directories ####

# FASTQ_SAMPLES_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}"
# CONCAT_SAMPLES_DIR="${SCRATCH_CONCAT_PWD}/${PROJECT_NAME}"
# BAM_SAMPLES_DIR="${SCRATCH_BAM_PWD}/${PROJECT_NAME}"

FASTQ_SAMPLES_DIR="/mnt/beegfs/scratch/j_wang/01_RawData/19_XPCtox/F23A430001132-01_HOMnifuR_20230823163641/soapnuke/clean/batch_03/"
CONCAT_SAMPLES_DIR="/mnt/beegfs/scratch/j_wang/02_ConcatData/19_XPCtox/F23A430001132-01_HOMnifuR_20230823163641/soapnuke/clean/batch_03/"

#### do genome routine analysis 
DO_PIPELINE=true
ANALYSIS_PIPELINE_SRC_DIR="/home/j_wang@intra.igr.fr/Genome_Sequencing_Analysis"

#### do check md5sum of fastq raw data file
DO_MD5SUM=false
#### md5sum file path
MD5SUM_FILE=""
MD5SUM_MODULE_SRC_DIR="${ANALYSIS_PIPELINE_SRC_DIR}/workflow/rules/md5sum"

#### do concatenation of fastq raw data read 1 and 2 
DO_CONCAT=true
CONCAT_MODULE_SRC_DIR="${ANALYSIS_PIPELINE_SRC_DIR}/workflow/rules/data/concat"

#### do oncokb and civic annotation
DO_CLINIC=false
CLINIC_MODULE_SRC_DIR="${ANALYSIS_PIPELINE_SRC_DIR}/workflow/rules/clinic"

#### do backup of fastq raw data
DO_BACKUP_FASTQ=true

#### do backup of concatenated fastq raw data
DO_BACKUP_CONCAT=false

#### do backup of bam file 
DO_BACKUP_BAM=true

#### do backup of all analysis results
DO_BACKUP_RESULTS=true

#######################################
#### init pipelline work directory ####
#######################################

WORKING_DIR="${SCRATCH_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}"

mkdir -p ${WORKING_DIR}
cd ${WORKING_DIR}

echo "change pwd to ${WORKING_DIR}"

#### if variable of concated sample directory is defined but DNA_samples doesn't exist, then create the DNA_samples directory
if [ ! -z "${CONCAT_SAMPLES_DIR}" ] && [ ! -d DNA_samples ] ; then
    echo "init DNA_samples directory" ; 
    mkdir -p DNA_samples ;
fi

#### if variable of bam sample directory is defined but bam directory doesn't exist, then create the directory
if [ ! -z "${BAM_SAMPLES_DIR}" ] && [ ! -d bam ] ; then
    echo "init bam file direcotry" ; 
    mkdir -p bam ;
fi

#### if variant call table is given, then cp to current dir, otherwise create an empty table
if [ ! -f ${VAR_TABLE} ] ; then
    echo "init empty variant call table" ;
    touch "variant_call_list_${MODE}.tsv" ;
else
    echo "copy the variant call table to current directory"
    cp ${VAR_TABLE} .
fi

#### if workflow is not ln to src, then create a softlink
if [ ! -d workflow ] ; then
    if [ -z ${ANALYSIS_PIPELINE_SRC_DIR} ] ; then 
	echo "init softlink to main branch of pipeline" ;
	ln -s /home/j_wang@intra.igr.fr/Genome_Sequencing_Analysis/workflow .
    else
	echo "link to specific branch of analysis pipeline [${ANALYSIS_PIPELINE_SRC_DIR}]"
	ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow . ;
    fi 
fi

exit 0

############################
#### verify md5sum code ####
############################

if [ $DO_MD5SUM == true ] ; then
    echo "verify md5sum"
fi

############################
#### concat fastq files ####
############################

#########################
#### start pipelline ####
#########################

if ( [ -d DNA_samples ] || [ -d bam ] ) && [ -f ${VAR_TABLE} ] && [ -d workflow ] ; then
    echo "Starting pipeline" ;
    module load java ;
    /mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --latency-wait 50 --rerun-incomplete --config samples=${SAMPLES} seq_type=${SEQ_TYPE} mode=${MODE} ;

fi 

###########################
#### backup to storage ####
###########################
