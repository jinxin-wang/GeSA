#!/usr/bin/bash

#### define colors
OKGREEN='\033[92m'
WARNING='\033[93m'
FAIL='\033[91m'
ENDC='\033[0m'

set -e

#######################################################
####                 PATH CONVENTION               #### 
#######################################################

DOWNLOAD_TAG="logs/.download.tag"
CONCAT_TAG="logs/.concat.tag"

DNA_PIPELINE_TAG="logs/.dna_pipeline.tag"
RNA_FUS_PIPELINE_TAG="logs/.rna_fusion_pipeline.tag"
RNA_SEQ_PIPELINE_TAG="logs/.rna_seq_pipeline.tag"

CLINIC_TAG="logs/.clinic.tag"
BACKUP_TAG="logs/.backup.tag"

## Convention: Path should not terminated by /

FASTQS_DIR="01_RawData"
CONCATS_DIR="02_ConcatData"
RESULTS_DIR="03_Results"
BAMS_DIR="04_BamData"

BACKUP_PWD="/mnt/glustergv0/U981/NIKOLAEV"
SCRATCH_PWD="/mnt/beegfs/scratch/${USER}"

SCRATCH_FASTQ_PWD="${SCRATCH_PWD}/${FASTQS_DIR}"
SCRATCH_CONCAT_PWD="${SCRATCH_PWD}/${CONCATS_DIR}"
SCRATCH_WORKING_PWD="${SCRATCH_PWD}/${RESULTS_DIR}"

#### #### #### #### #### #### #### #### ####
####       default global variables     ####
#### #### #### #### #### #### #### #### ####

TODAY=`date +%Y%m%d`

#### project name: [01_BCC|04_XP_SKIN|05_XP_INTERNAL|17_UV_MMR|19_XPCtox|20_POLZ|21_DEN|23_|....]
BCC="01_BCC"
XPSKIN="04_XP_SKIN"
XPINTERNAL="05_XP_INTERNAL"
NF2="15_NF2"
UV_MMR="17_UV_MMR"
XPCtox="19_XPCtoxins"
POLZ="20_POLZ"
DEN="21_DEN"
ALCLAK="ALCL_AK"
ATACseq="ATACseq_epiProbe"
FD02="FD02"
METARPISM="META_PRISM"
NEIL3="NEIL3_CISPL"
STING="STING_UNLOCK"

######################################## raw data directories ########################################
EGA="EGA"
IRODS="iRODS"
AMAZON="S3"
BGI="GeneAn"
FTP="ftp"
STORAGE="backup"

DO_DOWNLOAD=false
DATABASE=

DO_MD5SUM=false
MD5SUM_FILE="md5sum.txt"

###################### do concatenation of fastq raw data read 1 and 2 ####################################
DO_CONCAT=false

###################### do genome routine analysis ##########################
DO_PIPELINE=false
# ANALYSIS_PIPELINE_SRC_DIR="/home/j_wang@intra.igr.fr/Genome_Sequencing_Analysis"
# ANALYSIS_PIPELINE_SRC_DIR="/home/j_wang@intra.igr.fr/Workspace/GSA_AndreiM_Final"

#### snakemake settings
APP_SNAKEMAKE="/mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake"
SNAKEMAKE_JOBS_NUM=20

#### data file types:
FASTQ="fastq"
BAM="bam"

DATA_FILETYPE=${FASTQ}

#### samples: [human|mouse], default: human
HUMAN="human"
MOUSE="mouse"

#### seq type: [WGS|WES], default: WGS
WGS="WGS"
WES="WES"
RNA="RNA"

#### mode: [TvN|TvNp|Tp|T], default: TvN
TvN="TvN"
TvNp="TvNp"
Tp="Tp"
T="T"
N="N"

RNAFUS="RNAfusion"
RNASEQ="RNAseq"

NFCORE_VERSION=
NFCORE_VERSION_1P2="nfcore_1.2"
NFCORE_VERSION_2P1="nfcore_2.1"

#### pipeline default settings: 
SAMPLES="${HUMAN}"
SEQ_TYPE="${WES}"
MODE="${TvN}"

DO_CNVFACET=false
DO_ONCOTATOR=false

#### variant call table 
VAR_TABLE="variant_call_list_${MODE}.tsv"

#### nfcore sample sheet
NFCORE_SAMPLE_SHEET="config/nfcore_fusion_samplesheet.csv"

DO_CLINIC=false
PATIENTS_TABLE="config/patients.tsv"

DO_BAM2FASTQ=false

DO_BACKUP=false
DO_BACKUP_FASTQ=false
DO_BACKUP_CONCAT=false
DO_BACKUP_BAM=false
DO_BACKUP_RESULTS=false
DO_CLEAN_UP=false

#### script exec in interactive mode ####
INTERACT=true

#### #### #### #### #### #### #### #### ####
####           define functions         ####
#### #### #### #### #### #### #### #### ####

function enable_all_backup {
    DO_BACKUP=true ;
    DO_BACKUP_FASTQ=true ;
    DO_BACKUP_CONCAT=true ;
    DO_BACKUP_BAM=true ;
    DO_BACKUP_RESULTS=true ;
}

function disable_all_backup {
    DO_BACKUP=false ;
    DO_BACKUP_FASTQ=false ;
    DO_BACKUP_CONCAT=false ;
    DO_BACKUP_BAM=false ;
    DO_BACKUP_RESULTS=false ;
}

function enable_all_tasks {
    DO_DOWNLOAD=true ;
    DO_PIPELINE=true ;
    DO_MD5SUM=true ;
    DO_CONCAT=true ;
    DO_CLINIC=true ;
    enable_all_backup ;
}

function disable_all_tasks {
    DO_DOWNLOAD=false ;
    DO_PIPELINE=false ;
    DO_MD5SUM=false ;
    DO_CONCAT=false ;
    DO_CLINIC=false ;
    DO_BACKUP=false ;
    DO_BACKUP_FASTQ=false ; 
    DO_BACKUP_CONCAT=false ; 
    DO_BACKUP_BAM=false ; 
    DO_BACKUP_RESULTS=false ;
    DO_CLEAN_UP=false ;
}

function setup_storage_dir {

    SCRATCH_FASTQ_PWD=$1
    PROJECT_NAME=$2
    DATE=$3
    DATABASE=$4

    DEFAULT_STORAGE_DIR=${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}
    echo -e "${WARNING}[check point]${ENDC} Please provide the directory of raw data. [enter to continue with default path: ${OKGREEN}${DEFAULT_STORAGE_DIR}${ENDC} ] " >> `tty`
    read line
    if [ -z ${line} ] ; then
        STORAGE_DIR="${DEFAULT_STORAGE_DIR}" ;
    else 
        STORAGE_DIR=${line} ;
    fi
    echo ${STORAGE_DIR}
}

function setup_concat_dir {

    SCRATCH_FASTQ_PWD=$1
    PROJECT_NAME=$2
    DATE=$3
    DATABASE=$4

    DEFAULT_CONCAT_DIR=${SCRATCH_CONCAT_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}
    echo -e "${WARNING}[check point]${ENDC} Please provide the directory for the concatenation of raw data. [enter to continue with default path: ${OKGREEN}${DEFAULT_CONCAT_DIR}${ENDC} ] " >> `tty`
    read line ;
    if [ -z ${line} ] ; then
        CONCAT_DIR="${DEFAULT_CONCAT_DIR}" ;
    else
        CONCAT_DIR=${line} ;
    fi
    echo ${CONCAT_DIR}
}

function setup_sample_sheet {
    echo -e "${WARNING}[check point]${ENDC} Please provide the table of samples with information about the pairs of reads if it is possible " >> `tty`
    echo "The table must has at least 4 columns : sampleId, protocol, R1, R2 "
    echo "[enter to ignore or set the path]"
    read line
    if [ ! -z ${line} ] ; then
    	cp ${line} ${WORKING_DIR}/config/sample_sheet.tsv ;
    fi
}

function setup_variant_call {
    echo -e "${WARNING}[check point]${ENDC} Please provide the variant call table : [enter to continue and create the table later or set path now] " >> `tty`
    read line ;
    if [ ! -z ${line} ] && [ -f ${line} ] ; then
        cp ${line} ${WORKING_DIR}/config/variant_call_list_${MODE}.tsv ;
    fi
}

function join_by_char {
  local IFS="$1" ;
  shift ;
  echo "$*" ;
}

function prepare_download_from_ega {
    STORAGE_DIR=$1
    
    echo -e "${OKGREEN}[info]${ENDC} setup EGA download configuration file " >> `tty`
    DATABASE=${EGA} ;
    echo -e "${WARNING}[check point]${ENDC} please set the username [EGA account]: " >> `tty`
    read ega_username
    echo -e "${WARNING}[check point]${ENDC} please set the password [EGA account]: " >> `tty`
    read ega_password
    echo -e "{\"username\":\"${ega_username}\",\"password\":\"${ega_password}\"}" > ${WORKING_DIR}/config/ega_config.json
    echo -e "${WARNING}[check point]${ENDC} Do you need to check the list of your datasets: [y]/n ? " >> `tty`
    read line
    if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	/mnt/beegfs/userdata/j_wang/.conda/envs/pyEGA3/bin/pyega3 -cf ${WORKING_DIR}/config/ega_config.json datasets
    fi
    echo -e "${WARNING}[check point]${ENDC} please provide the datasets one by one, entre to continue" >> `tty`
    datasets_array=()
    while true ; do
	read line
	if [ -z ${line} ] ; then
	    break
	fi
	datasets_array[${#datasets_array[@]}]="'${line}'"
    done

    datasets="$(join_by_char ',' ${datasets_array[@]})"

    echo -e "${WARNING}[check point]${ENDC} Please set the number of connections, default: 100" >> `tty`
    read line
    if [ -z ${line} ] ; then
	conn=100
    else
	conn=${line}
    fi
    echo -e "DATABASE: '${DATABASE}' \nSTORAGE_PATH: '${STORAGE_DIR}' \n\nEGA_CONFIG_FILE: 'config/ega_config.json' \nEGA_DATASETS: [${datasets}] \nEGA_CONNECTIONS: ${conn}\n" > ${WORKING_DIR}/config/download.yaml
}

function prepare_download_from_irods {
    STORAGE_DIR=$1

    echo "${STORAGE_DIR}"
    
    echo -e "${OKGREEN}[info]${ENDC} setup iRODS download configuration file "
    DATABASE=${IRODS} ;

    echo -e "${WARNING}[check point]${ENDC} Please activate session to iRODS on cluster "
    iinit ;

    echo -e "${WARNING}[check point]${ENDC} Please provide the metadata sheet: [example: metadata.csv]"
    echo "datafilePath;sampleAlias"
    echo "/odin/kdi/dataset/2082179/archive/ST2194_N_S1_L003_R1_001.fastq.gz;ST2194_N"
    echo "/odin/kdi/dataset/2082179/archive/ST2194_N_S1_L003_R2_001.fastq.gz;ST2194_N"
    echo "/odin/kdi/dataset/2082181/archive/ST2194_T_S1_L003_R1_001.fastq.gz;ST2194_T"
    echo "/odin/kdi/dataset/2082181/archive/ST2194_T_S1_L003_R2_001.fastq.gz;ST2194_T"
    echo "/odin/kdi/dataset/2089132/archive/ST2194_R_EKRN230037912-1A_HJGVCDSX7_L3_1.fq.gz;ST2194_R"
    echo "/odin/kdi/dataset/2089132/archive/ST2194_R_EKRN230037912-1A_HJGVCDSX7_L3_2.fq.gz;ST2194_R"
    echo -e "\n\n[provide the path or enter to continue]"
    read metadata
    
    if [ ! -z ${metadata} ] && [ -f ${metadata} ] ; then
	echo -e "${WARNING}[check point]${ENDC} Please provide the column name of the file path in iRODS, default datafilePath. [enter to continue]"
	read coln_filepath ;
	if [ -z ${coln_filepath} ] ; then
	    coln_filepath="datafilePath"
	fi
	echo -e "${WARNING}[check point]${ENDC} Please provide the column name of sample ID, default sampleAlias. [enter to continue] "
	read coln_sampleid ;
	if [ -z ${coln_sampleid} ] ; then
	    coln_sampleid="sampleAlias"
	fi
	num_fastq_arr=($(wc -l ${metadata}))
	dataset_size=$((${num_fastq_arr[0]}*2))
    else
	echo -e "${WARNING}[check point]${ENDC} Please provide the bilan table of samples, [tsv/csv] "
	echo "for example: config/bilan.tsv"
	echo -e "PATIENT_ID\tPROTOCOL\tSampleType"
	echo -e "ST4359\tmRNA-seq\ttumor"
	echo -e "ST4359\tExome-seq\ttumor"
	echo -e "ST4359\tExome-seq\thealthy"
	echo "path of bilan table : "
	read bilan_table
	if [ ! -z ${bilan_table} ] && [ -f ${bilan_table} ] ; then
	    echo "[warning] table of samples is not found. "
	    exit -1 
	fi
	echo -e "${WARNING}[check point]${ENDC} Please provide the query names of project, for example STING, or STING_UNLOCK : "
	project_names_arr=()
	while true ; do
	    read line
	    if [ -z ${line} ] ; then
		break ;
	    fi
	    project_names_arr[${#project_names_arr[@]}]="'${line}'"
	done
	project_names="[$(join_by_char ',' ${project_names_arr[@]})]"

	echo -e "${WARNING}[check point]${ENDC} Please proivde the query key of sample ID in bilan table: "
	read bilan_query_key

	echo -e "${WARNING}[check point]${ENDC} Please provide the query key of sample ID in iRODS : "
	read dataset_query_key

	echo -e "${WARNING}[check point]${ENDC} Please provide the combined query keys of patient id, protocol, sample type in bilan table: "
	bilan_cquery_keys_arr=()
	for i in 1 2 3 ; do
	    read line
	    bilan_cquery_keys_arr[${#bilan_cquery_keys_arr[@]}]="'${line}'"
	done
	bilan_cquery_keys="[$(join_by_char ',' ${bilan_cquery_keys_arr[@]})]"
	
	echo -e "${WARNING}[check point]${ENDC} Please provide the combined query keys of patient id, protocol, sample type in iRODS: "
	dataset_cquery_keys_arr=()
	for i in 1 2 3 ; do
	    read line
	    dataset_cquery_keys_arr[${#dataset_cquery_keys_arr[@]}]="'${line}'"
	done
	dataset_cquery_keys="[$(join_by_char ',' ${dataset_cquery_keys_arr[@]})]"
	num_samples_arr=($(wc -l ${bilan_table})) ;
	dataset_size=$((${num_samples_arr[0]}*10)) ;
    fi

    echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\nDATASET_SIZE: ${dataset_size}\n\n" > ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_datasets_metadata: ${metadata}\niRODS_METADATA_SAMPLE_ID: ${coln_sampleid}\niRODS_METADATA_PATH: ${coln_filepath}\n\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_sample_bilan: ${bilan_table}\niRODS_PROJECT_NAMES: ${project_names}\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_BILAN_QUERY_KEY: ${bilan_query_key}\niRODS_DATASET_QUERY_KEY: ${dataset_query_key}\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_bilan_cquery_keys: ${bilan_cquery_keys}\niRODS_dataset_cquery_keys: ${dataset_cquery_keys}\n" >> ${WORKING_DIR}/config/download.yaml
}
			
function prepare_download_from_amazon_s3 {
    STORAGE_DIR=$1
    
    echo -e "${OKGREEN}[info]${ENDC} setup Amazon S3 download configuration file " >> `tty`
    DATABASE=${AMAZON} ;

    # access_key = AKIATBHNOLFVJG6VRUOG
    echo -e "${WARNING}[check point]${ENDC} Please provide the access key: [for example: AKIATBHNOLFVJG6VRUOG]" >> `tty`
    read access_key

    # secret_key = QkD5aMvi4MNsqlRy2yb03zGIDss9rxjjZaDcVkjx
    echo -e "${WARNING}[check point]${ENDC} Please provide the secret key: [for example: QkD5aMvi4MNsqlRy2yb03zGIDss9rxjjZaDcVkjx]" >> `tty`
    read secret_key
    
    # host_base  = s3-eu-west-3.amazonaws.com
    echo -e "${WARNING}[check point]${ENDC} Please provide the region: [for example: eu-west-3]" >> `tty`
    read region
    
    host_base="s3-${region}.amazonaws.com"
    host_bucket="%(bucket)s.${host_base}"

    echo -e "${WARNING}[check point]${ENDC} Please provide the path on amazon s3: [for example: s3://homlsxyr-598731762349/F23A430001132-04_HOMlsxyR ] " >> `tty`
    read s3_path

    echo -e "access_key = ${access_key} \nsecret_key = ${secret_key} \nhost_base = ${host_base} \nhost_bucket = ${host_bucket} \n" > ${WORKING_DIR}/config/s3_config.yaml
    
    echo -e "${OKGREEN}[info]${ENDC} checking total data size to download. This will take less than 1 min. Pleaes be patient ^_^b " >> `tty`
    line_arr=( $(/mnt/beegfs/userdata/j_wang/.conda/envs/aws/bin/s3cmd -c ${WORKING_DIR}/config/s3_config.yaml du ${s3_path} --human-readable) )
    dataset_size=${line_arr[0]}

    echo -e "${OKGREEN}[info]${ENDC} total data size: ${dataset_size} " >> `tty`
    
    echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\n\nS3_APP: /mnt/beegfs/userdata/j_wang/.conda/envs/aws/bin/s3cmd\nS3_PATH: ${s3_path}\n" > ${WORKING_DIR}/config/download.yaml
    echo -e "S3_CONFIG_FILE: ${WORKING_DIR}/config/s3_config.yaml\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "S3_DATASET_SIZE: ${dataset_size}\n" >> ${WORKING_DIR}/config/download.yaml
}

function prepare_download_from_bgi {
    STORAGE_DIR=$1

    echo -e "${OKGREEN}[info]${ENDC} setup BGI download configuration file "
    DATABASE=${BGI} ;

    echo -e "${WARNING}[check point]${ENDC} Please provide the username of GeneAn account: [example: FhwAlb4pr5slwe6@genean.addr]"
    read user

    echo -e "${WARNING}[check point]${ENDC} Please provide the password of GeneAn account: [example: hy__cb@Hy@fjxzrz]"
    read passwd

    echo -e "${WARNING}[check point]${ENDC} Verify the login and password: "
    /mnt/beegfs/userdata/j_wang/BGI_GENEAN/ferry login 
    
    /mnt/beegfs/userdata/j_wang/BGI_GENEAN/ferry project
    echo -e "${WARNING}[check point]${ENDC} Please provide the project name or project No. "
    read dataset

    echo -e "${WARNING}[check point]${ENDC} Please provide the path of the project on GeneAn Cloud: [default: '/'] "
    read cpath
    if [ -z ${cpath} ] ; then
	cpath='/'
    fi

    echo -e "${WARNING}[check point]${ENDC} Please estimate the size of the dataset: "
    read dataset_size
    
    echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\nDATASET_SIZE: ${dataset_size}\n\n" > ${WORKING_DIR}/config/download.yaml
    echo -e "BGI_APP: '/mnt/beegfs/userdata/j_wang/BGI_GENEAN/ferry'\nBGI_USERNAME: ${user}\nBGI_PASSWORD: ${passwd}\nBGI_dataset: ${dataset}\nBGI_CLOUDPATH: ${cpath}\n" >> ${WORKING_DIR}/config/download.yaml
}

function prepare_download_from_ftp_server {
    STORAGE_DIR=$1

    echo -e "${OKGREEN}[info]${ENDC} setup FTP server download configuration file "
    DATABASE=${FTP} ;

    ftp_app="/mnt/beegfs/userdata/j_wang/.conda/envs/work/bin/lftp"
    
    echo -e "${WARNING}[check point]${ENDC} Please provide the username of ftp server: "
    read username

    echo -e "${WARNING}[check point]${ENDC} Please provide the password of ftp server: "
    read passwd 

    echo -e "${WARNING}[check point]${ENDC} Please provide the host or ip address of ftp server: "
    read hostaddr

    echo -e "${WARNING}[check point]${ENDC} Please provide the directory to download on the ftp server: "
    /mnt/beegfs/userdata/j_wang/.conda/envs/work/bin/lftp -c "set ftp:ssl-allow no; open -u ${username}, ${passwd} ${hostaddr} ; ls "
    echo -e "\n\nThe directory to download is : [default: .] "
    read dataset
    if [ -z ${dataset} ] ; then
	dataset='.'
    fi

    line_arr=( $(/mnt/beegfs/userdata/j_wang/.conda/envs/work/bin/lftp -c "set ftp:ssl-allow no; open -u ${username}, ${passwd} ${hostaddr} ; du -s --block-size=1073741824 ${dataset} ") )
    dataset_size="${line_arr[0]}G"
    
    echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\nDATASET_SIZE: ${dataset_size}\n\n" > ${WORKING_DIR}/config/download.yaml
    echo -e "FTP_APP: '/mnt/beegfs/userdata/j_wang/.conda/envs/work/bin/lftp'\nFTP_USERNAME: ${username}\nFTP_PASSWORD: ${passwd}\nFTP_HOST: ${hostaddr}\nFTP_DATASET: ${dataset}\n" >> ${WORKING_DIR}/config/download.yaml
}

function prepare_download_from_backup_storage {
    STORAGE_DIR=$1

    if [ -z ${CLUSTER_STORAGE} ] ; then 
	echo -e "${WARNING}[check point]${ENDC} Please provide the directory on the backup storage: " >> `tty`
	read CLUSTER_STORAGE
    else
	echo -e "${WARNING}[check point]${ENDC} the directory on the backup storage is ${CLUSTER_STORAGE}, is that correct ? [enter to continue, or provide the directory] " >> `tty`
	read line
	if [ ! -z ${line} ] ; then
	    CLUSTER_STORAGE=${line} ;
	fi
    fi

    # echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\n\n" > ${WORKING_DIR}/config/download.yaml
    # echo -e "CLUSTER_STORAGE: ${cluster_storage}" >> ${WORKING_DIR}/config/download.yaml
    mkdir -p ${STORAGE_DIR} ; 
    echo "rsync -avh --progress ${CLUSTER_STORAGE} ${STORAGE_DIR} ; "
}

function choose_database {
    echo -e "${WARNING}[check point]${ENDC} please choose the database by the number : \n  1. EGA \n  2. iRODS \n  3. Amazon S3 \n  4. BGI GeneAn \n  5. FTP Server \n  6. From backup storage " >> `tty`
    read line
    case $line in 
    1 ) DATABASE=${EGA} ;;
    2 ) DATABASE=${IRODS} ;;
    3 ) DATABASE=${AMAZON} ;;
    4 ) DATABASE=${BGI} ;;
    5 ) DATABASE=${FTP} ;;
    6 ) DATABASE=${STORAGE} ;;
    * ) DATABASE=${line} ;;
    esac
    echo ${DATABASE}
}

function prepare_download {

    PROJECT_NAME=$1
    DATABASE=$2
    STORAGE_DIR=$3
    
    case ${DATABASE} in 
    ${EGA} ) 
        prepare_download_from_ega ${STORAGE_DIR} ;
        build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
    ${IRODS} )
        prepare_download_from_irods ${STORAGE_DIR} ;
        build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
    ${AMAZON} )
        prepare_download_from_amazon_s3 ${STORAGE_DIR} ;
        build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
    ${BGI} )
        prepare_download_from_bgi ${STORAGE_DIR} ;
        build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
    ${FTP} )
        prepare_download_from_ftp_server ${STORAGE_DIR} ;
        build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
    ${STORAGE} )
        cmd="$(prepare_download_from_backup_storage ${STORAGE_DIR})" ;
        echo "${cmd}" >> ${RUN_PIPELINE_SCRIPT} ;;
    esac

}

function build_download_cmd {
    
    PROJECT_NAME=$1
    STORAGE_DIR=$2
    PIPELINE_SCRIPT=$3
    
    # 	--cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' \
    #   --jobs ${SNAKEMAKE_JOBS_NUM} --latency-wait 50 --rerun-incomplete  --use-conda \
    
    echo "
rm -f workflow ;
ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow workflow ;
touch ${DOWNLOAD_TAG} ;
DOWNLOAD_TAG=\$(grep 'complete' ${DOWNLOAD_TAG} | wc -l) ;
if [ ! -d ${STORAGE_DIR} ] && [ ${DOWNLOAD_TAG} -eq 0 ] ; then 
    echo 'downloading raw data to ${STORAGE_DIR}' ;
    module load java ;
    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ;	
    CONFIG_OPTIONS=' PROJECT_NAME=${PROJECT_NAME} STORAGE_PATH=${STORAGE_DIR} ' ;
    snakemake \\
        --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web \\
        -s workflow/rules/data/download/entry_point.smk \\
        --configfile config/download.yaml \\
        --config \${CONFIG_OPTIONS} ;
    conda deactivate ;
    echo 'complete' > ${DOWNLOAD_TAG} ;
fi " >> ${PIPELINE_SCRIPT} ;

}

function build_md5sum_cmd {

    WORKING_DIR=$1
    STORAGE_DIR=$2
    PIPELINE_SCRIPT=$3

    echo "MD5SUM_LOG=${WORKING_DIR}/config/md5sum_check.log
cd ${STORAGE_DIR} ; 
" >> ${RUN_PIPELINE_SCRIPT} ;
    
    echo 'find_arr=($(find . -name "*md5*txt")) ; 
if [ -f ${MD5SUM_LOG} ] && [ $(grep FAILED ${MD5SUM_LOG} | wc -l) -eq 0 ] ; then
    echo -e "[info] md5sum had been verified previously. "
elif [ ${#find_arr[@]} == 1 ] ; then
    echo -e "[info] The md5sum file: ${find_arr[0]} "
    echo -e "[info] starting to verify md5sum [Ctrl+C to cancel if the md5sum file is not correct]" ;
    srun --mem=10240 -p shortq -D . -c 4 md5sum -c ${find_arr[0]} | tee ${MD5SUM_LOG} ;
else
    if [ ${#find_arr[@]} -gt 1 ] ; then
        echo -e "[info] Possible md5sum files: "
        for fname in "${find_arr[@]}" ; do
            echo " - ${fname}"
        done
    fi 
    echo "Please provide the md5sum file: [enter to continue] "
    read MD5SUM_FILE ;
    echo -e "[info] starting to verify md5sum " ;
    srun --mem=10240 -p shortq -D . -c 4 md5sum -c ${MD5SUM_FILE} | tee ${MD5SUM_LOG} ;
fi ' >> ${RUN_PIPELINE_SCRIPT} ;

    echo "cd ${WORKING_DIR} ; " >> ${RUN_PIPELINE_SCRIPT} ;
}

function build_concat_cmd {

    STORAGE_DIR=$1 ;
    CONCAT_DIR=$2  ;
    PIPELINE_SCRIPT=$3 ;
    
    echo "
rm -f workflow ;
ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow workflow ;
touch ${CONCAT_TAG} ;
concat_success=\$(grep 'complete' ${CONCAT_TAG} | wc -l) ;

if [ ! -d ${CONCAT_DIR} ] && [[ ${concat_success} -eq 0 ]] ; then 
    echo '[info] Starting to concatenate the raw data to directory ${CONCAT_DIR}' ;
    module load java ; 
    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ;
    snakemake \\
        --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web \\
        -s workflow/rules/data/concat/entry_point.smk \\
        --configfile workflow/config/concat.yaml \\
        --config raw_fastq_dir=${STORAGE_DIR} concat_fastq_dir=${CONCAT_DIR} ;
    conda deactivate ;
    echo 'complete' > ${CONCAT_TAG} ;
fi " >> ${PIPELINE_SCRIPT} ;
}

function setup_backup_submodule {
    # if [ ${INTERACT} != false ] && [ ${DO_DOWNLOAD} == false ] && [ ${DO_CONCAT} == false ] && [ ${DO_PIPELINE} == false ] && [ ${DO_CLINIC} == false ] ; then
    if [ ${INTERACT} != false ] ; then
	disable_all_backup ;
	echo -e "${WARNING}[check point]${ENDC} Do you need to activate and setup backup to storage ? [y]/n"
	read line
	if [ ! -z ${line} ] || [ ${line,,} == "n" ] || [ ${line,,} == "no" ] ; then
	    # echo -e "${FAIL}[warning]${ENDC} Noting to be done."
	    DO_BACKUP=false ;
	else
	    DO_BACKUP=true ;
	fi
    fi

    if [ ${DO_BACKUP} == true ] ; then 
	echo -e "${WARNING}[check point]${ENDC} Please set the path of backup storage [enter to continue with default path : ${BACKUP_PWD} ]"
	read line ;
	if [ ! -z ${line} ]  ; then
	    BACKUP_PWD=${line} ;
	fi

	echo -e "${WARNING}[check point]${ENDC} Do you need to backup raw data ? [y]/n"
	read line ;
	if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	    DO_BACKUP_FASTQ=true
	fi

	echo -e "${WARNING}[check point]${ENDC} Do you need to backup concatenated data ? [y]/n"
	read line ;
	if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	    DO_BACKUP_CONCAT=true
	fi

	echo -e "${WARNING}[check point]${ENDC} Do you need to backup bam files ? [y]/n"
	read line ;
	if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	    DO_BACKUP_BAM=true
	fi

	echo -e "${WARNING}[check point]${ENDC} Do you need to backup analysis results of pipeline ? [y]/n"
	read line ;
	if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	    DO_BACKUP_RESULTS=true
	fi
    fi
}

function backup_results {
    if [ $DO_BACKUP_RESULTS == true ] ; then
	echo -e "${OKGREEN}[info]${ENDC} backup analysis results to storage"
	mkdir -p ${BACKUP_RESULTS_PWD} ;
	echo "echo '[info] starting to backup analysis results to storage: ${BACKUP_RESULTS_PWD} '" >> ${RUN_PIPELINE_SCRIPT} ;
	for dir in ${BACKUP_TARGETS[@]} ; do
	    echo "
    if [ -d ${dir} ] ; then 
	rsync -avh --progress ${dir} ${BACKUP_RESULTS_PWD} ; 
    fi " >> ${RUN_PIPELINE_SCRIPT} ;
	done
    fi
}

function backup_raw {
    #### do backup of fastq raw data
    if [ $DO_BACKUP_FASTQ == true ] && [ ${DATABASE} != ${STORAGE} ] ; then
	echo -e "${OKGREEN}[info]${ENDC} backup raw fastq files to storage"
	mkdir -p ${BACKUP_FASTQ_PWD} ;
	echo "echo '[info] starting to backup raw data to storage: ${BACKUP_FASTQ_PWD} '" >> ${RUN_PIPELINE_SCRIPT} ;
	echo "rsync -avh --progress ${STORAGE_DIR} ${BACKUP_FASTQ_PWD} ; " >> ${RUN_PIPELINE_SCRIPT} ;
	if  [ ${DO_BACKUP_RESULTS} == true ] ; then 
	    echo "ln -s  ${BACKUP_FASTQ_PWD} ${BACKUP_RESULTS_PWD}/RAW_FASTQ ; " >> ${RUN_PIPELINE_SCRIPT} ; 
	fi
    fi
}

function backup_concat {
    #### do backup of concatenated fastq raw data
    if [ $DO_BACKUP_CONCAT == true ] && [ ${DATABASE} != ${STORAGE} ] ; then
	echo -e "${OKGREEN}[info]${ENDC} backup concat fastq files to storage"
	mkdir -p ${BACKUP_CONCATS_PWD} ;
	echo "echo '[info] starting to backup concatenated fastq to storage: ${BACKUP_CONCATS_PWD} '" >> ${RUN_PIPELINE_SCRIPT} ;
	echo "rsync -avh --progress ${CONCAT_DIR} ${BACKUP_CONCATS_PWD} ; " >> ${RUN_PIPELINE_SCRIPT} ;
	if [ ${DO_BACKUP_RESULTS} == true ] ; then
	    echo "ln -s ${BACKUP_CONCATS_PWD} ${BACKUP_RESULTS_PWD}/CONCAT_FASTQ ; " >> ${RUN_PIPELINE_SCRIPT} ;
	fi
    fi
}

function backup_bam {
    #### do backup of bam file
    if [ $DO_BACKUP_BAM == true ] && [ ${DATABASE} != ${STORAGE} ] ; then
	echo -e "${OKGREEN}[info]${ENDC} backup bam files to storage"
	mkdir -p ${BACKUP_BAM_PWD} ;
	echo "echo '[info] starting to backup bam files to storage: ${BACKUP_BAM_PWD} '" >> ${RUN_PIPELINE_SCRIPT} ;
	echo "rsync -avh --progress bam ${BACKUP_BAM_PWD} ; " >> ${RUN_PIPELINE_SCRIPT} ;
	if [ ${DO_BACKUP_RESULTS} == true ] ; then
	    echo "ln -s ${BACKUP_BAM_PWD} ${BACKUP_RESULTS_PWD}/bam ; " >> ${RUN_PIPELINE_SCRIPT} ;
	fi
    fi 
} 

function pipeline_complete {
    echo -e "\necho '[Congratulations] Everything has been done. '" >> ${RUN_PIPELINE_SCRIPT} ;
    chmod u+x  ${RUN_PIPELINE_SCRIPT} ;
    mkdir -p ${WORKING_DIR}/logs/slurm/ ${WORKING_DIR}/logs/tags/ ; 
    echo -e "${OKGREEN}[Congratulations]${ENDC} The working directory is finally ready, to start the pipeline, please execute the commands as follow: \n\t cd ${WORKING_DIR}\n\t ./run.sh "
}

#######################################
####           parse args          ####
#######################################
DATE=
BATCH_POSTFIX=

function help {
    echo "Usage: dna_pipeline_assistant [options]

    This script help you to prepare the working directory and generate the script of entire process, including download the data then check md5sum, concatenation of reads, analysis of the samples, annotation by civic and oncokb, and backup everything to storage.

    mandatory arguments :

    --project-name
	$BCC $XPSKIN $XPINTERNAL $NF2 ${UV_MMR}
	$XPCtox $POLZ $DEN $ALCLAK $ATACseq
	$FD02 $METARPISM $NEIL3 $STING

    --download-DB
	${EGA}, ${IRODS}, ${AMAZON}, ${BGI}, ${FTP}, ${STORAGE}

    --pipeline-sample-species
	$HUMAN, $MOUSE

    --pipeline-sequencing-protocol
	WGS, WES, RNA-seq

    --pipeline-analysis-mode

	for WGS or WES:
	    TvN  - Tumor vs Normal
	    T    - Tumor Only
     	    N    - Normal Only
	    Tp   - Tumor vs Pon
	    TvNp - Tumor vs Normal vs Pon

	for RNA-seq:
	    RNAfusion analysis (nfcore version 1.2 or 2.1)
	    RNAseq analysis

    optional arguments :

    -a, --all
    	enable all the submodules: download, md5check, concat, analysis, civic and oncokb annotation, backup

    -s, --silence
    	non-interactive mode (not recommended)

    --date
	format: YYYYMMDD
	default: ${TODAY}

    --batch-postfix
	add postfix to working directory name      

    enable submodules : 
        --download
        --md5check
        --concat
        --pipeline
	--clinic
        --backupALL
        --backupFASTQ
        --backupCONCAT
        --backupBAM
        --backupRESULTS

    download submodule arguments :

    	--download-configfile

	--cluster-storage

    check md5sum submodule arguments :

        --md5check-file

    concat submodule arguments :

        --concat-sample-list
	    a tsv file contains list of sample, it can be the variant call table.

	--concat-src
	    raw data directory

	--concat-to
	    concat data directory
	   
    analysis pipeline submodule arguments :

    	--pipeline-branch
	    set a specific branch of pipeline

	--pipeline-data-filetype
	    $FASTQ , $BAM

	--cnvfacet
	    activate cnv_facet submodule

	--oncotator
	    activate oncotator submodule

    civic and oncokb annotation submodule arguments :

        --clinic

    backup submodule arguments :

    "
    exit 0
}

SHORT_OPTS=a,s,h

MANDATORY_OPTS=project-name:,pipeline-analysis-mode:,pipeline-sequencing-protocol:,pipeline-sample-species:,download-DB:
GENERAL_OPTS=date:,rawDIR:,pipelineDIR:,backupDIR:,batch-postfix:,silence,help
DOWNLOAD_OPTS=download,download-configfile:,cluster-storage: 
MD5SUM_OPTS=md5check,md5check-file:,
CONCAT_OPTS=concat,concat-sample-list:,concat-src:,concat-to:
PIPELINE_OPTS=pipeline,clinic,pipeline-branch:,pipeline-data-filetype:,cnvfacet,oncotator,bam2fastq
BACKUP_OPTS=backupALL,backupFASTQ,backupCONCAT,backupBAM,backupRESULTS

LONG_OPTS=${MANDATORY_OPTS},${GENERAL_OPTS},${DOWNLOAD_OPTS},${MD5SUM_OPTS},${CONCAT_OPTS},${PIPELINE_OPTS},${BACKUP_OPTS}

OPTS=$(getopt -a -n run_pipeline --options ${SHORT_OPTS} --longoptions ${LONG_OPTS} -- "$@")

eval set -- "$OPTS"

while true ; do
    case "$1" in
	-a | --all )
	    enable_all_tasks ; shift ;;
	--project-name )
	    PROJECT_NAME=$2 ; shift 2 ;;
	--batch-postfix ) 
	    BATCH_POSTFIX=$2 ; shift 2 ;;
        --date ) 
	    DATE=$2 ; shift 2 ;;
	
	--download )
	    DO_DOWNLOAD=true ; 
	    DO_MD5SUM=true ;
	    DO_CONCAT=true ; 
	    DO_PIPELINE=true ; 
	    enable_all_backup ;
	    shift ;;
	--download-configfile )
	    DO_DOWNLOAD=true ; 
	    DOWNLOAD_CONFIGFILE=$2 ; shift 2 ;;
	--download-DB )
	    DO_DOWNLOAD=true ; 
	    DATABASE=$2 ; shift 2 ;;
	--cluster-storage )
	    DO_DOWNLOAD=true ; 
	    CLUSTER_STORAGE=$2 ; shift 2 ;;

	--md5check )
	    DO_MD5SUM=true ; 
	    DO_CONCAT=true ; 
	    DO_PIPELINE=true  ;
	    enable_all_backup ;
	    shift ;;
	--md5check-file )
	    DO_MD5SUM=true ; 
	    MD5SUM_FILE=$2 ; 
	    shift 2 ;;
	
	--concat )
	    DO_CONCAT=true ; 
	    DO_PIPELINE=true ; 
	    enable_all_backup ;
	    shift ;;  
	--concat-sample-list )
	    DO_CONCAT=true ; 
	    FASTQ_SAMPLE_LIST=$2 ;
	    shift 2 ;;	    
	--concat-src )
	    DO_CONCAT=true ; 
	    STORAGE_DIR=$2 ;
	    shift 2 ;;  
	--concat-to )
	    DO_CONCAT=true ; 
	    CONCAT_DIR=$2 ;
	    shift 2 ;;
	
	--pipeline )
	    DO_PIPELINE=true ; 
	    enable_all_backup ;
	    shift ;;  
	--pipeline-branch )
	    PIPELINE_BRANCH=$2 ;
	    shift 2 ;;
	--pipeline-sample-species )
	    SAMPLES=$2 ;
	    shift 2 ;;
	--pipeline-sequencing-protocol ) 
	    SEQ_TYPE=$2 ;
	    shift 2 ;;
	--pipeline-analysis-mode )
	    MODE=$2 ;
	    shift 2 ;;
	--pipeline-data-filetype )
	    DATA_FILETYPE=$2 ;
	    shift 2 ;;
	--cnvfacet )
	    DO_CNVFACET=true ;
	    shift ;;
	--oncotator )
	    DO_ONCOTATOR=true ;
	    shift ;;
	--clinic )
	    DO_CLINIC=true ;
	    shift ;;
	--bam2fastq )
            DO_BAM2FASTQ=true ;
	    shift ;;
	
	--backup )
	    enable_all_backup ;
	    shift ;; 
	--backupFASTQ )
	    DO_BACKUP=true ;
	    DO_BACKUP_FASTQ=true ;
	    shift ;; 
	--backupCONCAT )
	    DO_BACKUP=true ;
	    DO_BACKUP_CONCAT=true ;
	    shift ;; 
	--backupBAM )
	    DO_BACKUP=true ;
	    DO_BACKUP_BAM=true ;
	    shift ;; 
	--backupRESULTS )
	    DO_BACKUP=true ;
	    DO_BACKUP_RESULTS=true ;
	    shift ;;
	
	-s | --silence )
	    INTERACT=false ;
	    shift ;;
	-h | --help )
	    help; exit 0 ;;
	
	-- ) shift; break ;; 
	* ) break ;; 
    esac
done

if [ -z ${PROJECT_NAME} ] ; then
    if [ ${INTERACT} == true ] ; then
	echo -e -e "${WARNING}[check point]${ENDC} Please set project name by choosing the number: \n  1. BCC\n  2. XP SKIN \n  3. XP INTERNAL \n  4. NF2 \n  5. UV_MMR \n  6. XPCtox \n  7. POLZ \n  8. DEN \n  9. ALCLAK \n  10. ATACseq \n  11. FD02 \n  12. METARPISM \n  13. NEIL3 \n  14. STING UNLOCK \nIf the name does not exist in the list, please set the name directly: "
    
	read choice
    
	case ${choice} in
	    1 )
		PROJECT_NAME=${BCC} ;;
	    2 )
		PROJECT_NAME=${XPSKIN} ;;
	    3 )
		PROJECT_NAME=${XPINTERNAL} ;;
	    4 )
		PROJECT_NAME=${NF2} ;;
	    5 )
		PROJECT_NAME=${UV_MMR} ;;
	    6 )
		PROJECT_NAME=${XPCtox} ;;
	    7 )
		PROJECT_NAME=${POLZ} ;;
	    8 )
		PROJECT_NAME=${DEN} ;;
	    9 )
		PROJECT_NAME=${ALCLAK} ;;
	    10)
		PROJECT_NAME=${ATACseq} ;;
	    11)
		PROJECT_NAME=${FD02} ;;
	    12)
		PROJECT_NAME=${METARPISM} ;;
	    13)
		PROJECT_NAME=${NEIL3} ;;
	    14)
		PROJECT_NAME=${STING} ;;
	    *   )
	    PROJECT_NAME=${choice} ;;
	esac
	
	echo -e "\nProject name: ${PROJECT_NAME} \n"
    else
	echo -e "${FAIL}[Error]${ENDC} --project-name is a mandatory option. "
	exit -1 ;

    fi
fi

#### default analysis results directory:
if [ -z ${DATE} ] ; then
    DATE=${TODAY}
fi

if [ ${INTERACT} == true ] ; then
    echo -e "${WARNING}[check point]${ENDC} The species of sample is ${SAMPLES}, is that correct ? [enter to continue or choose the number to change]"
    echo -e "1. human\n2. mice"
    read line
    if [ ! -z ${line} ] ; then
        case ${line} in 
    	    1 ) SAMPLES=${HUMAN} ;;
    	    2 ) SAMPLES=${MOUSE} ;;
    	    * ) echo "Unknown choice !" ; exit -1 ;;
    	esac
    fi

    echo -e "${WARNING}[check point]${ENDC} The sequencing protocol is ${SEQ_TYPE}, is that correct ? [enter to continue or choose the number to change] "
    echo -e "1. WGS\n2. WES\n3. RNA-seq"
    read line
    if [ ! -z ${line} ] ; then
	case ${line} in 
	    1 ) SEQ_TYPE=${WGS} ;;
	    2 ) SEQ_TYPE=${WES} ;;
	    3 ) SEQ_TYPE=${RNA} ;;
	    * ) echo "Unknown choice !" ; exit -1 ;;
	esac
    fi

    if [ ${SEQ_TYPE} == ${RNA} ] ; then
	echo -e "${WARNING}[check point]${ENDC} Please choose the RNA analysis pipeline by number "
	echo -e "1. RNA fusion analysis \n2. RNA-seq analysis"
	read line ;
	if [ ! -z ${line} ] ; then
    	    case ${line} in 
    		1 ) MODE=${RNAFUS} ;;
    		2 ) MODE=${RNASEQ} ;;
    		* ) echo "Unknown choice !" ; exit -1 ;;
    	    esac
	fi

	if [ ${MODE} == ${RNAFUS} ] ; then 
	    echo -e "${WARNING}[check point]${ENDC} Please choose the version of nfcore fusion pipeline by number: "
	    echo -e "1. version 1.2\n2. version 2.1"
	    read line ;

            if [ ! -z ${line} ] ; then
		case ${line} in
                    1 ) NFCORE_VERSION=${NFCORE_VERSION_1P2} ;;
                    2 ) NFCORE_VERSION=${NFCORE_VERSION_2P1} ;;
                    * ) echo "Unknown choice !" ; exit -1    ;;
		esac
            fi
	fi

    elif [ ${SEQ_TYPE} == ${WGS} ] || [ ${SEQ_TYPE} == ${WES} ] ; then
	echo -e "${WARNING}[check point]${ENDC} The analysis mode is ${MODE}, is that correct ? [enter to continue or choose the number to change] "
	echo -e "1. TvN - Tumor vs Normal \n2. T - Tumor Only\n3. N - Normal Only \n4. Tp - Tumor vs Pon\n5. TvNp - Tumor vs Normal vs Pon"

	read line
	if [ ! -z ${line} ] ; then
    	    case ${line} in 
    		1 ) MODE=${TvN} ;;
    		2 ) MODE=${T} ;;
    		3 ) MODE=${N} ;;
    		4 ) MODE=${Tp} ;;
    		5 ) MODE=${TvNp} ;;
    		* ) echo "Unknown choice !" ; exit -1 ;;
    	    esac
	fi
	
	echo -e "${WARNING}[check point]${ENDC} The file type of data is ${DATA_FILETYPE}, is that correct ? [enter to continue or choose the number to change] "
	echo -e "1. fastq files\n2. bam files"
	read line
	if [ ! -z ${line} ] ; then
    	    case ${line} in 
    		1 ) DATA_FILETYPE=${FASTQ} ;;
    		2 ) DATA_FILETYPE=${BAM} ;;
    		* ) echo "Unknown choice !" ; exit -1 ;;
    	    esac
	fi
    fi

    if [ ! -z ${BATCH_POSTFIX} ] ; then 
        echo -e "${WARNING}[check point]${ENDC} The postfix of the batch is ${BATCH_POSTFIX}, is that correct ? [enter to continue or correct the batch name] "
    else 
        echo -e "${WARNING}[check point]${ENDC} What is the postfix of the batch ? [enter to ignore or set the batch name] "
    fi
    read line 
    if [ ! -z ${line} ] ; then 
        BATCH_POSTFIX=${line}
    fi

else 
    echo -e "${OKGREEN}[info]${ENDC} The species of sample is ${SAMPLES}. "
    echo -e "${OKGREEN}[info]${ENDC} The analysis mode of pipeline is ${MODE}. "
    echo -e "${OKGREEN}[info]${ENDC} The sequencing protocol is ${SEQ_TYPE}. "
    echo -e "${OKGREEN}[info]${ENDC} The file type of data is ${DATA_FILETYPE}."
    if [ ! -z ${BATCH_POSTFIX} ] ; then 
        echo -e "${OKGREEN}[info]${ENDC} The postfix of batch is ${BATCH_POSTFIX}."
    fi
fi

RESULT_BATCH_NAME="${DATE}_${SAMPLES}_${SEQ_TYPE}_${MODE}"

if [ ${MODE} == ${RNAFUS} ] && [ ! -z ${NFCORE_VERSION} ] ; then 
    RESULT_BATCH_NAME="${DATE}_${SAMPLES}_${RNAFUS}_${NFCORE_VERSION}" ;
elif [ ${MODE} == ${RNASEQ} ] ; then 
    RESULT_BATCH_NAME="${DATE}_${SAMPLES}_${RNASEQ}" ;
fi

if [ ! -z ${BATCH_POSTFIX} ] ; then
    RESULT_BATCH_NAME="${RESULT_BATCH_NAME}_${BATCH_POSTFIX}" ;
fi

# if not abs. path, convert rela. path to abs.
if [ -f ${VAR_TABLE} ] & [[ ${VAR_TABLE} != /* ]] ; then
    VAR_TABLE="${PWD}/${VAR_TABLE}"
fi

#######################################
#### init pipelline work directory ####
#######################################

echo -e "\n\n${OKGREEN}[info]${ENDC} start initializing the working directory..."

## current directory is where user execute the interactive bash script
CURRENT_DIR="$PWD"

## working directory is where the pipeline store the results to
WORKING_DIR="${SCRATCH_WORKING_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}"

echo -e "${OKGREEN}[info]${ENDC} pipeline working directory: ${OKGREEN}${WORKING_DIR}${ENDC}"

mkdir -p ${WORKING_DIR}/config

RUN_PIPELINE_SCRIPT=${WORKING_DIR}/"run.sh"

echo -e "#!/usr/bin/bash\n\nset -e ; \nsource ~/.bashrc ;\n\n" > ${RUN_PIPELINE_SCRIPT}

#### if workflow is not ln to src, then create a softlink
# if [ ! -d ${WORKING_DIR}/workflow ] ; then
#     if [ ${INTERACT} == true ] ; then
#         echo -e "${WARNING}[check point]${ENDC} Directory of pipeline is ${ANALYSIS_PIPELINE_SRC_DIR} : [y]/n "
#         read line
#         if [ ! -z ${line} ] && ( [ ${line,,} == "n" ] || [ ${line,,} == "no" ] ) ; then
#             echo "Please set the directory of pipeline: "
#             read ANALYSIS_PIPELINE_SRC_DIR
#         fi
#     fi
# 
#     echo -e "${OKGREEN}[info]${ENDC} softlink to pipeline directory ${ANALYSIS_PIPELINE_SRC_DIR} " ;
#     ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow  ${WORKING_DIR}/workflow ;
# fi

############################################
####      Setup Download Submodule      ####
############################################

if [ ${INTERACT} == true ] ; then
    echo -e "\n\n${WARNING}[check point]${ENDC} Do you need to activate and setup download submodule ? [y]/n"
    read line ;
    if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	DO_DOWNLOAD=true ; 
	DO_MD5SUM=true ;
	DO_CONCAT=true ; 
	DO_PIPELINE=true ; 
	enable_all_backup ;
    else
    	DO_DOWNLOAD=false ;
    fi
fi

## Global variables:
## DATE
## MODE
## SAMPLES
## PROJECT_NAME
## DATA_FILETYPE
## WORKING_DIR
## RUN_PIPELINE_SCRIPT

## Download submodule needs :
## DATABASE
## STORAGE_DIR

if [ ${DO_DOWNLOAD} == true ] ; then

    echo -e "${OKGREEN}[info]${ENDC} start setting up the download submodule...."

    if [ ${INTERACT} == false ] && [ -z ${DATABASE} ] ; then
        echo -e "${FAIL}[Error]${ENDC} --download-DB is mandatory option :  ${EGA} , ${IRODS}, ${AMAZON}, ${BGI}, ${FTP}, ${STORAGE} "
        exit -1
    fi
    
    if [ ${INTERACT} == true ] && [ ! -f ${WORKING_DIR}/config/download.yaml ] ; then

        DATABASE=$(choose_database)

        if [ -z ${STORAGE_DIR} ] ; then 
            STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}"
        fi

        prepare_download ${PROJECT_NAME} ${DATABASE} ${STORAGE_DIR} ;

    elif [ ! -f ${WORKING_DIR}/config/download.yaml ] && [ ! -z ${DOWNLOAD_CONFIGFILE} ] && [ -f ${DOWNLOAD_CONFIGFILE} ] ; then
    	cp ${DOWNLOAD_CONFIGFILE} ${WORKING_DIR}/config/download.yaml ;
    
    	STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}" ;
    	
    	if [ ${DATABASE} == ${STORAGE} ] ; then
    	    echo "rsync -avh --progress ${CLUSTER_STORAGE} ${STORAGE_DIR} ; " >> ${RUN_PIPELINE_SCRIPT} ;
    	else
    	    build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;
    	fi
    
    else
        
    	if [ ! -f ${WORKING_DIR}/config/download.yaml ] ; then 
    	    echo -e "${OKGREEN}[info]${ENDC} copy an example of download configuration file to config/ directory, please setup the essential parameters" ;
    	    cp ${ANALYSIS_PIPELINE_SRC_DIR}/workflow/config/download.yaml ${WORKING_DIR}/config/ ;
    	fi
    	
    	STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}" ;
    
    	if [ ${DATABASE} == ${STORAGE} ] ; then
    	    echo "rsync -avh --progress ${CLUSTER_STORAGE} ${STORAGE_DIR} ; " >> ${RUN_PIPELINE_SCRIPT} ;
    	else
    	    build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;
    	fi
    fi
fi


#############################################################
####        setup verification of md5sum code block      ####
#############################################################

if [ ${INTERACT} == true ] && [ ${DO_DOWNLOAD} == false ] ; then
    echo -e "\n\n${WARNING}[check point]${ENDC} Do you need to activate and setup check md5sum block ? [y]/n"
    read line ;
    if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	DO_MD5SUM=true ;
	DO_CONCAT=true ;
	DO_PIPELINE=true ; 
	enable_all_backup ;
    else
	DO_MD5SUM=false ;
    fi
fi

## Global variables:
## DATE
## MODE
## SAMPLES
## PROJECT_NAME
## DATA_FILETYPE
## WORKING_DIR
## RUN_PIPELINE_SCRIPT

## md5sum block needs :
##  global: WORKING_DIR
##  global: RUN_PIPELINE_SCRIPT
## DATABASE
## STORAGE_DIR

if [ ${DO_MD5SUM} == true ] ; then

    echo -e "\n${OKGREEN}[info]${ENDC} start setting up the md5sum block...."

    if [ -z ${DATABASE} ] ; then 
        DATABASE=$(choose_database)
    fi

    if [ -z ${STORAGE_DIR} ] ; then 
        STORAGE_DIR=$(setup_storage_dir ${SCRATCH_FASTQ_PWD} ${PROJECT_NAME} ${DATE} ${DATABASE})
    fi
    
    if [ ${DATABASE} != ${IRODS} ] ; then 
	build_md5sum_cmd ${WORKING_DIR} ${STORAGE_DIR} ${PIPELINE_SCRIPT} ;
    fi 
fi

##################################################################################
####      if concat fastq directory is given, then add to config options      ####
##################################################################################
if [ ${INTERACT} == true ] ; then
    echo -e "${WARNING}[check point]${ENDC} Do you need to activate and setup concat submodule ? [y]/n"
    read line
    if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	DO_CONCAT=true ; 
	DO_PIPELINE=true ; 
	enable_all_backup ;
    else
	DO_CONCAT=false ;
	CONCAT_DIR=${STORAGE_DIR} ;
    fi
fi

## Global variables:
## DATE
## MODE
## SAMPLES
## PROJECT_NAME
## DATA_FILETYPE
## WORKING_DIR
## RUN_PIPELINE_SCRIPT

## concat submodule needs :
##  global: WORKING_DIR
##  global: RUN_PIPELINE_SCRIPT
## DATABASE
## STORAGE_DIR
## CONCAT_DIR

if [ ${DATA_FILETYPE} == ${FASTQ} ] && [ ${DO_CONCAT} == true ] ; then

    echo -e "\n${OKGREEN}[info]${ENDC} start setting up the concatenation submodule...."

    if [ -z ${DATABASE} ] && [ ${INTERACT} == false ] ; then
        echo -e "${FAIL}[Error]${ENDC} --download-DB is mandatory option for concatenation. "
        exit -1
    fi
    
    if [ -z ${DATABASE} ] && [ ${INTERACT} == true ] ; then
	DATABASE=$(choose_database) ;
    fi
            
    if [ -z ${STORAGE_DIR} ] && [ ${INTERACT} == true ] ; then
  	STORAGE_DIR=$(setup_storage_dir ${SCRATCH_FASTQ_PWD} ${PROJECT_NAME} ${DATE} ${DATABASE}) ;
    fi   

    if [ ${DO_DOWNLOAD} == false ] ; then
	echo -e "${OKGREEN}[info]${ENDC} The directory for the raw data : ${OKGREEN}${STORAGE_DIR}${ENDC}  "
    fi
	
    if [ -z "${CONCAT_DIR}" ] && [ ${INTERACT} == true ] ; then
	CONCAT_DIR=$(setup_concat_dir ${SCRATCH_FASTQ_PWD} ${PROJECT_NAME} ${DATE} ${DATABASE}) ;
    fi

    echo -e "${OKGREEN}[info]${ENDC} The directory for the concatenated data : ${OKGREEN}${CONCAT_DIR}${ENDC}  "

    CONFIG_OPTIONS=" raw_fastq_dir=${STORAGE_DIR} concat_fastq_dir=${CONCAT_DIR}" ;
    
    mkdir -p ${WORKING_DIR}/config/ ;
    
    if [ ${INTERACT} == true ] ; then 
	setup_sample_sheet ;
	setup_variant_call ;
    fi
	
    build_concat_cmd ${STORAGE_DIR} ${CONCAT_DIR} ${RUN_PIPELINE_SCRIPT} ;
fi

