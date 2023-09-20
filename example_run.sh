#!/usr/bin/bash

set -e

#######################################################
####                 PATH CONVENTION               #### 
#######################################################

## Convention: Path should not terminated by /

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

FASTQ_SAMPLES_BASE_DIR="/mnt/beegfs/scratch/j_wang/01_RawData/19_XPCtox/F23A430001132-01_HOMnifuR_20230823163641"
FASTQ_SAMPLES_RELA_DIR="soapnuke/clean/batch_03"
FASTQ_SAMPLES_DIR="/mnt/beegfs/scratch/j_wang/01_RawData/19_XPCtox/F23A430001132-01_HOMnifuR_20230823163641/soapnuke/clean/batch_03"

CONCAT_SAMPLES_DIR="/mnt/beegfs/scratch/j_wang/02_ConcatData/19_XPCtox/F23A430001132-01_HOMnifuR_20230823163641/soapnuke/clean/batch_03"

#### do genome routine analysis 
DO_PIPELINE=true
ANALYSIS_PIPELINE_SRC_DIR="/home/j_wang@intra.igr.fr/Workspace/GSA_AndreiM_Final"

#### do check md5sum of fastq raw data file
DO_MD5SUM=false
#### md5sum file path
MD5SUM_FILE=""
MD5SUM_LOG=${MD5SUM_FILE/.txt/.log}

#### do concatenation of fastq raw data read 1 and 2 
DO_CONCAT=true

#### do oncokb and civic annotation
DO_CLINIC=false
CLINIC_MODULE_SRC_DIR="${ANALYSIS_PIPELINE_SRC_DIR}/workflow/rules/clinic"

#### do backup of fastq raw data
DO_BACKUP_FASTQ=false

#### do backup of concatenated fastq raw data
DO_BACKUP_CONCAT=false

#### do backup of bam file 
DO_BACKUP_BAM=false

#### do backup of all analysis results
DO_BACKUP_RESULTS=false

#######################################
####           parse args          ####
#######################################

# help() {
#     echo "Usage: weather [ -c | --city1 ]
#                [ -d | --city2 ]
#                [ -h | --help  ]"
#     exit 2
# }

# SHORT=c:,d:,h
# LONG=city1:,city2:,help
# OPTS=$(getopt -a -n weather --options $SHORT --longoptions $LONG -- "$@")

# eval set -- "$OPTS"

# while :
# do
#   case "$1" in
#     -c | --city1 )
#       city1="$2"
#       shift 2
#       ;;
#     -d | --city2 )
#       city2="$2"
#       shift 2
#       ;;
#     -h | --help)
#       help ;
#       exit 0
#       ;;
#   esac
# done

#######################################
#### init pipelline work directory ####
#######################################

WORKING_DIR="${SCRATCH_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}"

mkdir -p ${WORKING_DIR}

#### copy the script run.sh to working directory
cp $0 ${WORKING_DIR}

cd ${WORKING_DIR}
echo "[message] change pwd to ${WORKING_DIR}"

#### if variable of concated sample directory is defined but DNA_samples doesn't exist, then create the DNA_samples directory
fastq_dir="DNA_samples"
if [ ! -z "${CONCAT_SAMPLES_DIR}" ] && [ ! -d ${fastq_dir} ] ; then
    echo "[message] init DNA_samples directory" ; 
    mkdir -p ${fastq_dir} ;
fi

#### if bam files are given, but bam directory doesn't exist, then create the directory
bam_dir="bam"
if [ ! -z "${BAM_SAMPLES_DIR}" ] && [ ! -d ${bam_dir} ] ; then
    echo "[message] init bam file direcotry" ; 
    mkdir -p ${bam_dir} ;
fi

#### if bam files are given, but bam directory is empty, then link to bam files
if [ ! -z "${BAM_SAMPLES_DIR}" ] && [ ! "$(ls ${bam_dir})" ] ; then 
    cd ${bam_dir} ;
    ln -s ${BAM_SAMPLES_DIR}/*bam . ; 
    cd .. ; 
fi

#### if variant call table is given, then cp to current dir, otherwise create an empty table
if [ ! -f ${VAR_TABLE} ] ; then
    echo "[message] init empty variant call table" ;
    touch "variant_call_list_${MODE}.tsv" ;
else
    echo "[message] copy the variant call table to current directory"
    cp ${VAR_TABLE} .
fi

#### if workflow is not ln to src, then create a softlink
if [ ! -d workflow ] ; then
    if [ -z ${ANALYSIS_PIPELINE_SRC_DIR} ] ; then 
	echo "[message] init softlink to main branch of pipeline" ;
	ln -s /home/j_wang@intra.igr.fr/Genome_Sequencing_Analysis/workflow .
    else
	echo "[message] link to specific branch of analysis pipeline [${ANALYSIS_PIPELINE_SRC_DIR}]"
	ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow . ;
    fi
fi

############################
#### verify md5sum code ####
############################

if [ $DO_MD5SUM == true ] ; then

    tmpfile=".failed.tmp"

    if [ -f ${MD5SUM_LOG} ] ; then
	echo "[message] md5sum had been verified previously. Ignore"
    else
	echo "[message] verify md5sum"
	md5sum -c ${MD5SUM_FILE} > ${MD5SUM_LOG}
    fi
    
    grep ": FAILED" ${MD5SUM_LOG} > ${tmpfile}
        
    if [ -s ${tmpfile} ] ; then
	echo "WARNING: Please check the samples, some files did NOT match md5sum" ; 
	cat ${tmpfile} ;
	exit -1
    fi

    rm -f ${tmpfile}
fi

#########################
#### start pipelline ####
#########################

CONFIG_OPTIONS="samples=${SAMPLES} seq_type=${SEQ_TYPE} mode=${MODE}"

#### if concat fastq directory is given, then add to config options
if [ ! -z "${CONCAT_SAMPLES_DIR}" ] ; then

    CONFIG_OPTIONS="${CONFIG_OPTIONS} concat_fastq_dir=${CONCAT_SAMPLES_DIR}" ;

    if [ ! -d "${CONCAT_SAMPLES_DIR}" ] ; then
	mkdir -p ${CONCAT_SAMPLES_DIR} ;
    fi
    
    if [ $DO_CONCAT == true ] ; then

	CONFIG_OPTIONS="${CONFIG_OPTIONS} do_concat=True raw_fastq_dir=${FASTQ_SAMPLES_DIR}" ; 

	cd "${CONCAT_SAMPLES_DIR}" ;
	for sn in * ; do
	    if grep -q "-" <<< "$sn"; then
		echo "[message] mv $sn ${sn//-/_} ; "
		mv $sn ${sn//-/_} ; 
	    fi
	done
	cd - ;
    fi
fi

# echo "CONFIG_OPTIONS=${CONFIG_OPTIONS}"

if ( [ -d ${fastq_dir} ] || [ -d ${bam_dir} ] ) && [ -f ${VAR_TABLE} ] && [ -d workflow ] ; then
    echo "[message] Starting pipeline" ;
    module load java ;
    mkdir -p logs/slurm/ ; 
    /mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --latency-wait 50 --rerun-incomplete --config ${CONFIG_OPTIONS} ;
fi 

###########################
#### backup to storage ####
###########################

#### do backup of all analysis results
echo "[message] backup analysis results to storage"
BACKUP_TARGETS=('fastq_QC_raw' 'fastq_QC_clean' 'haplotype_caller_filtered' 'annovar' 'mapping_QC' 'mapping_QC' 'cnv_facets' 'facets' 'Mutect2' 'oncotator_maf' 'oncotator_tsv_COSMIC_exom' 'annovar_mutect2')

if [ $DO_BACKUP_RESULTS == true ] ; then
    for dir in ${BACKUP_TARGETS} ; do
	if [ -d ${dir} ] && [ "$(ls ${dir})" ] ; then 
	    rsync -avh --progress ${dir} ${BACKUP_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME} ;
	fi
    done
fi

#### do backup of fastq raw data
echo "[message] backup raw fastq files to storage"
if [ $DO_BACKUP_FASTQ == true ] ; then
    rsync -avh --progress ${FASTQ_SAMPLES_BASE_DIR} ${BACKUP_FASTQ_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/ ;
    #### TODO: check md5sum !!!!!!!!!!!!!!!!!!!!!!
    mkdir -p ${BACKUP_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}/RAW_${fastq_dir}/
    ln -s  ${BACKUP_FASTQ_PWD}/${PROJECT_NAME}/${BACKUP_DATE} !$ ;
fi

#### do backup of concatenated fastq raw data
echo "[message] backup concat fastq files to storage"
if [ $DO_BACKUP_CONCAT == true ] ; then
    rsync -avh --progress ${CONCAT_SAMPLES_DIR}/* ${BACKUP_CONCAT_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/ ;
    mkdir -p ${BACKUP_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}/${fastq_dir}/
    cd !$ ; ln -s ${BACKUP_CONCAT_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/* . ; cd - ;
fi

#### do backup of bam file
echo "[message] backup bam files to storage"
if [ $DO_BACKUP_BAM == true ] ; then
    rsync -avh --progress ${bam_dir}/* ${BACKUP_BAM_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/ ;
    mkdir -p ${BACKUP_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}/${bam_dir}/
    cd !$ ; ln -s ${BACKUP_BAM_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/
fi 

#########################################
####         clean up scratch        ####
#########################################

# TODO
