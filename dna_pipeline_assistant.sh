#!/usr/bin/bash

set -e

#######################################################
####                 PATH CONVENTION               #### 
#######################################################

## Convention: Path should not terminated by /

FASTQS_DIR="01_RawData"
CONCATS_DIR="02_ConcatData"
RESULTS_DIR="03_Results"
BAMS_DIR="04_BamData"

BACKUP_PWD="/mnt/glustergv0/U981/NIKOLAEV/${USER^^}"
SCRATCH_PWD="/mnt/beegfs/scratch/${USER}"

BACKUP_FASTQ_PWD="${BACKUP_PWD}/${FASTQS_DIR}"
BACKUP_CONCATS_PWD="${BACKUP_PWD}/${CONCATS_DIR}"
BACKUP_RESULTS_PWD="${BACKUP_PWD}/${RESULTS_DIR}"
BACKUP_BAM_PWD="${BACKUP_PWD}/${BAMS_DIR}"

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
ANALYSIS_PIPELINE_SRC_DIR="/home/j_wang@intra.igr.fr/Workspace/GSA_AndreiM_Final"

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

#### mode: [TvN|TvNp|Tp|T], default: TvN
TvN="TvN"
TvNp="TvNp"
Tp="Tp"
T="T"

#### pipeline default settings: 
SAMPLES="${HUMAN}"
SEQ_TYPE="${WES}"
MODE="${TvN}"

DO_CNVFACET="False"
DO_ONCOTATOR="False"

#### variant call table 
VAR_TABLE="variant_call_list_${MODE}.tsv"

DO_CLINIC=false
PATIENTS_TABLE="config/patients.tsv"

DO_BACKUP_FASTQ=false
DO_BACKUP_CONCAT=false
DO_BACKUP_BAM=false
DO_BACKUP_RESULTS=false
DO_CLEAN_UP=false

#### script exec in interactive mode ####
INTERACT=false

function enable_all_backup {
    DO_BACKUP_FASTQ=true ;
    DO_BACKUP_CONCAT=true ;
    DO_BACKUP_BAM=true ;
    DO_BACKUP_RESULTS=true ;
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
    DO_BACKUP_FASTQ=false ; 
    DO_BACKUP_CONCAT=false ; 
    DO_BACKUP_BAM=false ; 
    DO_BACKUP_RESULTS=false ;
    DO_CLEAN_UP=false ;
}

function join_by_char {
  local IFS="$1" ;
  shift ;
  echo "$*" ;
}

function prepare_download_from_ega {
    STORAGE_DIR=$1
    
    echo "[info] setup EGA download configuration file "
    DATABASE=${EGA} ;
    echo "[check point] please set the username [EGA account]: "
    read ega_username
    echo "[check point] please set the password [EGA account]: "
    read ega_password
    echo -e "{\"username\":\"${ega_username}\",\"password\":\"${ega_password}\"}" > ${WORKING_DIR}/config/ega_config.json
    echo "[check point] Do you need to check the list of your datasets: [y/n] ? "
    read line
    if [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	/mnt/beegfs/userdata/j_wang/.conda/envs/pyEGA3/bin/pyega3 -cf ${WORKING_DIR}/config/ega_config.json datasets
    fi
    echo "[check point] please provide the datasets one by one, entre to continue"
    datasets_array=()
    while true ; do
	read line
	if [ -z ${line} ] ; then
	    break
	fi
	datasets_array[${#datasets_array[@]}]="'${line}'"
    done

    datasets="$(join_by_char ',' ${datasets_array[@]})"

    echo "[check point] Please set the number of connections, default: 100"
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
    
    echo "[info] setup iRODS download configuration file "
    DATABASE=${IRODS} ;

    echo "[check point] activate session to iRODS on cluster "
    iinit ;

    echo "[check point] Please provide the metadata sheet: [example: metadata.csv]"
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
	echo "[check point] Please provide the column name of the file path in iRODS, default datafilePath. [enter to continue]"
	read coln_filepath ;
	if [ -z ${coln_filepath} ] ; then
	    coln_filepath="datafilePath"
	fi
	echo "[check point] Please provide the column name of sample ID, default sampleAlias. [enter to continue] "
	read coln_sampleid ;
	if [ -z ${coln_sampleid} ] ; then
	    coln_sampleid="sampleAlias"
	fi
    else
	echo "[check point] Please provide the bilan table of samples, [tsv/csv] "
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
	echo "[check point] Please provide the query names of project, for example STING, or STING_UNLOCK : "
	project_names_arr=()
	while true ; do
	    read line
	    if [ -z ${line} ] ; then
		break ;
	    fi
	    project_names_arr[${#project_names_arr[@]}]="'${line}'"
	done
	project_names="[$(join_by_char ',' ${project_names_arr[@]})]"

	echo "[check point] Please proivde the query key of sample ID in bilan table: "
	read bilan_query_key

	echo "[check point] Please provide the query key of sample ID in iRODS : "
	read dataset_query_key

	echo "[check point] Please provide the combined query keys of patient id, protocol, sample type in bilan table: "
	bilan_cquery_keys_arr=()
	for i in 1 2 3 ; do
	    read line
	    bilan_cquery_keys_arr[${#bilan_cquery_keys_arr[@]}]="'${line}'"
	done
	bilan_cquery_keys="[$(join_by_char ',' ${bilan_cquery_keys_arr[@]})]"
	
	echo "[check point] Please provide the combined query keys of patient id, protocol, sample type in iRODS: "
	dataset_cquery_keys_arr=()
	for i in 1 2 3 ; do
	    read line
	    dataset_cquery_keys_arr[${#dataset_cquery_keys_arr[@]}]="'${line}'"
	done
	dataset_cquery_keys="[$(join_by_char ',' ${dataset_cquery_keys_arr[@]})]"
    fi

    echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\n\n" > ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_datasets_metadata: ${metadata}\niRODS_METADATA_SAMPLE_ID: ${coln_sampleid}\niRODS_METADATA_PATH: ${coln_filepath}\n\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_sample_bilan: ${bilan_table}\niRODS_PROJECT_NAMES: ${project_names}\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_BILAN_QUERY_KEY: ${bilan_query_key}\niRODS_DATASET_QUERY_KEY: ${dataset_query_key}\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_bilan_cquery_keys: ${bilan_cquery_keys}\niRODS_dataset_cquery_keys: ${dataset_cquery_keys}\n" >> ${WORKING_DIR}/config/download.yaml
}
			
function prepare_download_from_amazon_s3 {
    STORAGE_DIR=$1
    
    echo "[info] setup Amazon S3 download configuration file "
    DATABASE=${AMAZON} ;

    # access_key = AKIATBHNOLFVJG6VRUOG
    echo "[check point] Please provide the access key: [for example: AKIATBHNOLFVJG6VRUOG]"
    read access_key

    # secret_key = QkD5aMvi4MNsqlRy2yb03zGIDss9rxjjZaDcVkjx
    echo "[check point] Please provide the secret key: [for example: QkD5aMvi4MNsqlRy2yb03zGIDss9rxjjZaDcVkjx]"
    read secret_key
    
    # host_base  = s3-eu-west-3.amazonaws.com
    echo "[check point] Please provide the host base: [for example: s3-eu-west-3.amazonaws.com]"
    read host_base

    # host_bucket = %(bucket)s.s3-eu-west-3.amazonaws.com
    
    echo -e "access_key = ${access_key} \nsecret_key = ${secret_key} \nhost_base = ${host_base} \nhost_bucket = %(bucket)s.${host_base}\n" > ${WORKING_DIR}/config/s3_config.yaml

    echo "[check point] Please provide the directory of the dataset on amazon s3: [for example: f22ftseuht1706] "
    read dataset
    echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\n\nS3_APP: /mnt/beegfs/userdata/j_wang/.conda/envs/aws/bin/s3cmd\nS3_dataset: ${dataset}\n" > ${WORKING_DIR}/config/download.yaml

    echo -e "S3_CONFIG_FILE: ${WORKING_DIR}/config/s3_config.yaml\n" >> ${WORKING_DIR}/config/download.yaml

    echo "[info] checking total data size to download. "
    line_arr=( $(/mnt/beegfs/userdata/j_wang/.conda/envs/aws/bin/s3cmd -c ${WORKING_DIR}/config/s3_config.yaml du s3://${dataset} --human-readable) )
    dataset_size=${line_arr[0]}

    echo "[info] total data size: ${dataset_size} "
    echo -e "S3_DATASET_SIZE: ${dataset_size}\n" >> ${WORKING_DIR}/config/download.yaml
}

function prepare_download_from_bgi {
    STORAGE_DIR=$1

    echo "[info] setup BGI download configuration file "
    DATABASE=${BGI} ;

    echo "[check point] Please provide the username of GeneAn account: [example: FhwAlb4pr5slwe6@genean.addr]"
    read user

    echo "[check point] Please provide the password of GeneAn account: [example: hy__cb@Hy@fjxzrz]"
    read passwd

    echo "[check point] Please provide the project name or project No. "
    read dataset

    echo "[check point] Please provide the path of the project on GeneAn Cloud: "
    read cpath

   echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\n\n" > ${WORKING_DIR}/config/download.yaml
   echo -e "BGI_APP: '/mnt/beegfs/userdata/j_wang/BGI_GENEAN/ferry'\nBGI_USERNAME: ${user}\nBGI_PASSWORD: ${passwd}\nBGI_dataset: ${dataset}\nBGI_CLOUDPATH: ${cpath}\n" >> ${WORKING_DIR}/config/download.yaml
}

function prepare_download_from_ftp_server {
    STORAGE_DIR=$1

    echo "[info] setup FTP server download configuration file "
    DATABASE=${FTP} ;

    ftp_app="/mnt/beegfs/userdata/j_wang/.conda/envs/work/bin/lftp"
    
    echo "[check point] Please provide the username of ftp server: "
    read username

    echo "[check point] Please provide the password of ftp server: "
    read passwd 

    echo "[check point] Please provide the ip address of ftp server: "
    read hostaddr

    echo "[check point] Please provide the directory to download on the ftp server: "
    /mnt/beegfs/userdata/j_wang/.conda/envs/work/bin/lftp -c "set ftp:ssl-allow no; open -u ${username}, ${passwd} ${hostaddr} ; ls "
    echo -e "\n\nThe directory to download is : "
    read dataset

    echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\n\n" > ${WORKING_DIR}/config/download.yaml
    echo -e "FTP_APP: '/mnt/beegfs/userdata/j_wang/.conda/envs/work/bin/lftp'\nFTP_USERNAME: ${username}\nFTP_PASSWORD: ${passwd}\nFTP_SERVER_ADDR: ${hostaddr}\nFTP_DATASET: ${dataset}\n" >> ${WORKING_DIR}/config/download.yaml
}

function prepare_download_from_backup_storage {
    STORAGE_DIR=$1

    if [ -z ${CLUSTER_STORAGE} ] ; then 
	echo "[check point] Please provide the directory on the backup storage: "
	read CLUSTER_STORAGE
    else
	echo "[check point] the directory on the backup storage is ${CLUSTER_STORAGE}, is that correct ? [enter to continue, or provide the directory] "
	read line
	if [ ! -z ${line} ] ; then
	    CLUSTER_STORAGE=${line} ;
	fi
    fi

    # echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\n\n" > ${WORKING_DIR}/config/download.yaml
    # echo -e "CLUSTER_STORAGE: ${cluster_storage}" >> ${WORKING_DIR}/config/download.yaml
    echo "rsync -avh --progress ${CLUSTER_STORAGE} ${STORAGE_DIR} ; "
}

function prepare_variant_call_table {

    VARIANT_CALL_TABLE=${WORKING_DIR}/config/variant_call_list_${MODE}.tsv

    #### if variant call table is given, then cp to current dir, otherwise create an empty table
    if [ -f ${VARIANT_CALL_TABLE} ] ; then
	echo "[info] variant call table is ready: "
	cat ${VARIANT_CALL_TABLE} ;
	
    elif [ -f ${VAR_TABLE} ] ; then
	echo "[info] copy the variant call table to current directory"
	cp ${VAR_TABLE} ${VARIANT_CALL_TABLE} ;
	
    elif [ ${MODE} == ${TvN} ] || [ ${MODE} == ${TvNp} ]; then
	echo "[info] Generating variant call table..."
	cd ${FASTQ_SAMPLES_DIR} ;
	echo "[info] samples:  " ;
	ls ;
	nsamples=(*_N) ;
	tsamples=(*_T) ;
	cd - ;
	rm -f ${VARIANT_CALL_TABLE}
	for ((  i=0; i<${#nsamples[*]}; ++i )) ; do
	    tsam="${tsamples[$i]//_T/}" ;
	    nsam="${nsamples[$i]//_N/}" ;
	    if [[ ${tsam} != ${nsam} ]] ; then
		echo "[warning] tumor sample name ${tsam} DOSE NOT CORRESPOND TO normal sample name ${nsam} !" ;
		break
	    fi
	    echo -e "${tsamples[$i]}\t${nsamples[$i]}" >> ${VARIANT_CALL_TABLE} ;
	done

	echo "[info] variant call table is done: "
	cat ${VARIANT_CALL_TABLE} ;
	
    elif [ ${MODE} == ${T} ] || [ ${MODE} == ${Tp} ] ; then
	echo "[info] Generating variant call table..."
	cd ${FASTQ_SAMPLES_DIR} ;
	echo "[info] samples:  " ;
	ls ;
	tsamples=(*) ;
	cd - ;
	rm -f ${VARIANT_CALL_TABLE} ;
	for ((  i=0; i<${#tsamples[*]}; ++i )) ; do
	    echo -e "${tsamples[$i]}" >> ${VARIANT_CALL_TABLE} ;
	done
	echo "[info] variant call table is done: "
	cat variant_call_list_${T}.tsv ;

    elif [ ${INTERACT} == true ] ; then
	    echo "Please provide the variant call table location: "
	    read VAR_TABLE
	    cp ${VAR_TABLE} ${VARIANT_CALL_TABLE} ;
    else
	    echo "[info] init empty variant call table..." ;
	    touch ${VARIANT_CALL_TABLE} ;
    fi

}

function check_md5sum_file {
    ## if md5sum file doesn't exist, search in raw fastq data directory.
    ## user need to choose the correct one
    if [ ${INTERACT} == true ] && [ ! -f ${MD5SUM_FILE} ] ; then
	for md5 in `find ${FASTQ_SAMPLES_DIR} -name "*md5*txt" ` ; do
	    echo "[INTERVENE] Is ${md5} the md5sum file ? [y/n]" ; 
	    read line ;
	    if [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
		echo "OK"
		MD5SUM_FILE=${md5} ;
		break ;
	    fi
	done
    fi

    ## if not found, specify the location
    if  [ ${INTERACT} == true ] && [ ! -f ${MD5SUM_FILE} ] ; then
	echo "[INTERVENE] Please specify the md5sum file location: " ;
	read MD5SUM_FILE ;
    fi

    ## exist if all failed.
    if  [ ! -f ${MD5SUM_FILE} ] ; then
	echo "[ERROR] Unable to find the md5 file. Please check!"
	exit -1
    fi
}

function build_download_cmd {
    
    PROJECT_NAME=$1
    STORAGE_DIR=$2
    PIPELINE_SCRIPT=$3
    
    # 	--cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' \
    #   --jobs ${SNAKEMAKE_JOBS_NUM} --latency-wait 50 --rerun-incomplete  --use-conda \
    
    echo "
echo 'downloading raw data to ${STORAGE_DIR}' ;
module load java ;
conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ;	
mkdir -p logs/slurm ; 
CONFIG_OPTIONS=' PROJECT_NAME=${PROJECT_NAME} STORAGE_PATH=${STORAGE_DIR} ' ;
snakemake \\
    --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web \\
    -s workflow/rules/data/download/entry_point.smk \\
    --configfile config/download.yaml \\
    --config \${CONFIG_OPTIONS} ;
conda deactivate ; " >> ${PIPELINE_SCRIPT} ;

}

function build_concat_cmd {
    # 	--cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' \
    #	--jobs ${SNAKEMAKE_JOBS_NUM} --latency-wait 50 --rerun-incomplete \

    STORAGE_DIR=$1 ;
    CONCAT_DIR=$2  ;
    PIPELINE_SCRIPT=$3 ;
    
    echo "
if [ ! -f config/sample_sheet.tsv ] && [ ! -f config/variant_call_list_${MODE}.tsv ] ; then
    echo '[Error] Please check if sample_sheet.tsv or variant_call_list_${MODE}.tsv is set in the config directory. '
    exit -1
fi

echo '[info] Starting to concatenate the raw data to directory ${CONCAT_DIR}' ;
module load java ; 
conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ;
mkdir -p ${CONCAT_DIR} ; 
snakemake \\
    --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web \\
    -s workflow/rules/data/concat/entry_point.smk \\
    --configfile workflow/config/concat.yaml \\
    --config raw_fastq_dir=${STORAGE_DIR} concat_fastq_dir=${CONCAT_DIR} ;
conda deactivate ;" >> ${PIPELINE_SCRIPT} ;
}

function build_pipeline_cmd {

    CONFIG_OPTIONS="$1"
    CONCAT_DIR="$2"
    PIPELINE_SCRIPT="$3"

    echo '
if [ -z "$(ls DNA_samples)"  ] ; then '  >> ${PIPELINE_SCRIPT} ;
    
    echo "
    ln -s ${CONCAT_DIR}/*gz DNA_samples" >> ${PIPELINE_SCRIPT} ;
    
    echo '
    cd DNA_samples
    for s in * ; do
        s1=${s//-/_}   ;
        s2=${s1//__/_} ;
        mv ${s} ${s2}  ;
    done
    cd ..
fi ' >> ${PIPELINE_SCRIPT} ;
    
    echo "
echo '[check point] Please check if the variant call table is correct: [enter to continue]'
cat config/variant_call_list*tsv ;
read line

echo '[info] Starting ${SAMPLES} ${SEQ_TYPE} pipeline ${MODE} mode' ;
module load java ;
mkdir -p logs/slurm/ ; 
rm -f bam/*tmp* ;
${APP_SNAKEMAKE} \\
    --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' \\
    --jobs ${SNAKEMAKE_JOBS_NUM} --latency-wait 50 --rerun-incomplete \\
    --config ${CONFIG_OPTIONS} " >> ${PIPELINE_SCRIPT} ;
    
}

function build_oncokb_civic_cmd {

    PIPELINE_SCRIPT=$1
    
    echo '
if [ -f config/patients.tsv ] ; then
    echo "[check point] please provide patients table" ;
    read line
    if [ -f ${line} ] ; then
        cp ${line} config/patients.tsv
    fi
fi ' >> ${PIPELINE_SCRIPT}

    echo "
echo 'Starting oncokb and civic annotation' ; 
conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ; 
## 2.0 generate configuration files
snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/config/entry_point.smk  ;
## 2.1 mut. oncokb and civic annotations
snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/mut/TvN/entry_point.smk ;
## 2.2 cna. oncokb and civic annotations
snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/cna/entry_point.smk     ;
conda deactivate ; " >> ${PIPELINE_SCRIPT}

}

#######################################
####           parse args          ####
#######################################
DATE=
BATCH_POSTFIX=

function help {
    echo "Usage: dna_pipeline [cmd] [options]

    "
    exit 0
}

SHORT_OPTS=a,i,h

MANDATORY_OPTS=project-name:,pipeline-analysis-mode:,pipeline-sequencing-protocol:,pipeline-sample-species:,download-DB:
GENERAL_OPTS=date:,downloadDB:,rawDIR:,workDIR:,pipelineDIR:,backupDIR:,batch-postfix:,interact,unlock,help
DOWNLOAD_OPTS=download,download-configfile:,cluster-storage: # ,download-DB:,download-to:,
MD5SUM_OPTS=md5check,md5check-file:,
CONCAT_OPTS=concat,concat-sample-list:,concat-src:,concat-to:
PIPELINE_OPTS=pipeline,clinic,pipeline-branch:,pipeline-analysis-batch:,pipeline-data-filetype:
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
	    DO_DOWNLOAD=true ; shift ;;
	--download-configfile )
	    DOWNLOAD_CONFIGFILE=$2 ; shift 2 ;;
	--download-DB )
	    DATABASE=$2 ; shift 2 ;;
	--cluster-storage )
	    CLUSTER_STORAGE=$2 ; shift 2 ;;

	--md5check )
	    DO_MD5SUM=true ; shift ;;
	--md5check-file )
	    DO_MD5SUM=true ; shift 2 ;;
	
	--concat )
	    DO_CONCAT=true ; shift ;;
	--concat-sample-list )
	    FASTQ_SAMPLE_LIST=$2 ;
	    shift 2 ;;	    
	--concat-src )
	    FASTQ_SAMPLES_DIR=$2 ;
	    shift 2 ;;  
	--concat-to )
	    CONCAT_DIR=$2 ;
	    shift 2 ;;
	
	--pipeline )
	    DO_PIPELINE=true ; shift ;;  
	--pipeline-branch )
	    PIPELINE_BRANCH=$2 ; shift 2 ;;
	--pipeline-sample-species )
	    SAMPLES=$2 ; shift 2 ;;
	--pipeline-sequencing-protocol ) 
	    SEQ_TYPE=$2 ; shift 2 ;;
        --pipeline-analysis-mode )
	    MODE=$2 ; shift 2 ;;
	--pipeline-analysis-batch )
	    BATCH_POSTFIX=$2 ; shift 2 ;;
	--pipeline-data-filetype )
	    DATA_FILETYPE=$2 ; shift 2 ;;

	--clinic )
	    DO_CLINIC=true ; shift ;;
	
	--backup )
	    enable_all_backup ; shift ;; 
	--backupFASTQ )
	    DO_BACKUP_FASTQ=true ; shift ;; 
	--backupCONCAT )
	    DO_BACKUP_CONCAT=true ; shift ;; 
	--backupBAM )
	    DO_BACKUP_BAM=true ; shift ;; 
	--backupRESULTS )
	    DO_BACKUP_RESULTS=true ; shift ;;
	
	-i | --interact )
	    INTERACT=true ; shift ;;
	--unlock )
	    DO_UNLOCK=true ; shift ;;
	-h | --help )
	    help; exit 0 ;;
	-- ) shift; break ;; 
	* ) break ;; 
    esac
done

if [ -z ${PROJECT_NAME} ] ; then
    if [ ${INTERACT} == true ] ; then
	echo -e "[check point] Please set project name by choosing the number: \n  1. BCC\n  2. XP SKIN \n  3. XP INTERNAL \n  4. NF2 \n  5. UV_MMR \n  6. XPCtox \n  7. POLZ \n  8. DEN \n  9. ALCLAK \n  10. ATACseq \n  11. FD02 \n  12. METARPISM \n  13. NEIL3 \n  14. STING UNLOCK \nfor any other project, please provide the name directly: \n "
    
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
	echo "[Error] --project-name is a mandatory option. "
	exit -1 ;

    fi
fi

#### default analysis results directory:
if [ -z ${DATE} ] ; then
    DATE=${TODAY}
fi

if [ ${INTERACT} == true ] ; then
    echo "[check point] The species of sample is ${SAMPLES}, is that correct ? [enter to continue or choose by the number]"
    echo -e "1. human\n2. mice"
    read line
    if [ ! -z ${line} ] ; then
	case ${line} in 
	    1 ) SAMPLES=${HUMAN} ;;
	    2 ) SAMPLES=${MOUSE} ;;
	    * ) echo "Unknown choice !" ; exit -1 ;;
	esac
    fi

    echo "[check point] The sequencing protocol is ${SEQ_TYPE}, is that correct ? [enter to continue or choose by the number] "
    echo -e "1. WGS\n2. WES"
    read line
    if [ ! -z ${line} ] ; then
	case ${line} in 
	    1 ) SEQ_TYPE=${WGS} ;;
	    2 ) SEQ_TYPE=${WES} ;;
	    * ) echo "Unknown choice !" ; exit -1 ;;
	esac
    fi

    echo "[check point] The analysis mode is ${MODE}, is that correct ? [enter to continue or choose by the number] "
    echo -e "1. TvN - Tumor vs Normal \n2. T - Tumor Only\n3. Tp - Tumor vs Pon\n4. TvNp - Tumor vs Normal vs Pon"
    read line
    if [ ! -z ${line} ] ; then
	case ${line} in 
	    1 ) MODE=${TvN} ;;
	    2 ) MODE=${T} ;;
	    3 ) MODE=${Tp} ;;
	    4 ) MODE=${TvNp} ;;
	    * ) echo "Unknown choice !" ; exit -1 ;;
	esac
    fi

    echo "[check point] The file type of data is ${DATA_FILETYPE}, is that correct ? [enter to continue or choose by the number] "
    echo -e "1. fastq files\n2. bam files"
    read line
    if [ ! -z ${line} ] ; then
	case ${line} in 
	    1 ) DATA_FILETYPE=${FASTQ} ;;
	    2 ) DATA_FILETYPE=${BAM} ;;
	    * ) echo "Unknown choice !" ; exit -1 ;;
	esac
    fi

else 
    echo "[info] The species of sample is ${SAMPLES}. "
    echo "[info] The analysis mode of pipeline is ${MODE}. "
    echo "[info] The sequencing protocol is ${SEQ_TYPE}. "
    echo "[info] The file type of data is ${DATA_FILETYPE}."
fi

RESULT_BATCH_NAME="${DATE}_${SAMPLES}_${SEQ_TYPE}_${MODE}"

if [ ! -z ${BATCH_POSTFIX} ] ; then
    RESULT_BATCH_NAME="${RESULT_BATCH_NAME}_${BATCH_POSTFIX}"
fi

# if not abs. path, convert rela. path to abs.
if [ -f ${VAR_TABLE} ] & [[ ${VAR_TABLE} != /* ]] ; then
    VAR_TABLE="${PWD}/${VAR_TABLE}"
fi

RUN_PIPELINE_SCRIPT="run_pipeline.sh"

echo -e "#!/usr/bin/bash\n\nset -e ; \nsource ~/.bashrc ;\n\n" > ${RUN_PIPELINE_SCRIPT}

#######################################
#### init pipelline work directory ####
#######################################

## current directory is where user execute the interactive bash script
CURRENT_DIR="$PWD"

## working directory is where the pipeline store the results to
WORKING_DIR="${SCRATCH_WORKING_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}"

echo "[info] pipeline working directory: ${WORKING_DIR}"

mkdir -p ${WORKING_DIR}/config

#### if workflow is not ln to src, then create a softlink
if [ ! -d ${WORKING_DIR}/workflow ] ; then
    if [ ${INTERACT} == true ] ; then
	echo "[check point]Directory of pipeline is ${ANALYSIS_PIPELINE_SRC_DIR} : [y/n] "
	read line
	if [ ${line,,} == "n" ] || [ ${line,,} == "no" ] ; then
	    echo "Please specify the directory of pipeline: "
	    read ANALYSIS_PIPELINE_SRC_DIR
	fi
    fi
    # cp ${ANALYSIS_PIPELINE_SRC_DIR}/workflow/config/config.json ${WORKING_DIR}/config ;
    echo "[info] softlink to pipeline directory ${ANALYSIS_PIPELINE_SRC_DIR} " ;
    ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow  ${WORKING_DIR}/workflow ;
fi

if [ ${DO_DOWNLOAD} == true ] ; then

    if [ ${INTERACT} == false ] && [ -z ${DATABASE} ] ; then
	echo "[Error] --download-DB is mandatory option :  ${EGA} , ${IRODS}, ${AMAZON}, ${BGI}, ${FTP}, ${STORAGE} "
	exit -1
    fi
    
    if [ ${INTERACT} == true ] && [ ! -f ${WORKING_DIR}/config/download.yaml ] ; then
	echo "[check point] Please set the download configuration file:  [enter to continue]" ;
	read line ;

	if [ ! -z ${line} ] && [ -f ${line} ] ; then
	    echo "[info] copy your download configuration file to config/ "
	    cp ${line} ${WORKING_DIR}/config/download.yaml ;
	    echo "[info] ${WORKING_DIR}/config/download.yaml : "
	    cat ${WORKING_DIR}/config/download.yaml
	    echo "[info] end of the configuration file "

	else
	    echo -e "[check point] please choose the database by the number : \n  1. EGA \n  2. iRODS \n  3. Amazon S3 \n  4. BGI GeneAn \n  5. FTP Server \n  6. From backup storage \n"
	    read line
	    
	    case $line in 
		1 )
		    DATABASE=${EGA}
		    STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${EGA}"
		    prepare_download_from_ega ${STORAGE_DIR} ;
		    build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
		2 )
		    DATABASE=${IRODS}
		    STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${IRODS}"
		    prepare_download_from_irods ${STORAGE_DIR} ;
		    build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
		3 )
		    DATABASE=${AMAZON}
		    STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${AMAZON}"
		    prepare_download_from_amazon_s3 ${STORAGE_DIR} ;
		    build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
		4 )
		    DATABASE=${BGI}
		    STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${BGI}"
		    prepare_download_from_bgi ${STORAGE_DIR} ;
		    build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
		5 )
		    DATABASE=${FTP}
		    STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${FTP}"
		    prepare_download_from_ftp_server ${STORAGE_DIR} ;
		    build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
		6 )
		    DATABASE=${STORAGE}
		    STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${STORAGE}" ;
		    cmd="$(prepare_download_from_backup_storage ${STORAGE_DIR})" ;
		    echo "${cmd}" >> ${RUN_PIPELINE_SCRIPT} ;;
	    esac
	fi

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
	    echo "[info] copy an example of download configuration file to config/ directory, please setup the essential parameters" ;
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

#########################################
####         verify md5sum code      ####
#########################################

if [ ${DO_MD5SUM} == true ] ; then

    echo "find_arr=($(find ${STORAGE_DIR} -name \"*md5sum*txt\")) ; " >> ${RUN_PIPELINE_SCRIPT} ;

    echo '
if [ ${#find_arr[@]} == 1 ] ; then
    line=${find_arr[0]}
    echo "[info] The md5sum file: ${find_arr[0]} "
else
    if [ ${#find_arr[@]} > 1 ] ; then
        echo "[info] Possible md5sum files: "
        for fname in "${find_arr[@]}" ; do
	    echo " - ${fname}"
	done
    fi 
    echo "Please provide the md5sum file: [enter to continue] "
    read line
fi

if [ ! -z ${line} ] ; then
    MD5SUM_FILE=${line}
    MD5SUM_LOG=${MD5SUM_FILE/.txt/.log}
fi
' >> ${RUN_PIPELINE_SCRIPT} ;

    echo "cd ${STORAGE_DIR} ; " >> ${RUN_PIPELINE_SCRIPT} ;
    
    echo '
if [ -f ${MD5SUM_LOG} ] ; then
    echo "[info] md5sum had been verified previously. "
elif [ ! -z ${MD5SUM_FILE} ] ; then 
    echo "[info] starting to verify md5sum "
    srun --mem=40960 -p shortq -D . -c 20 md5sum -c ${MD5SUM_FILE} > ${MD5SUM_LOG} ;
fi' >> ${RUN_PIPELINE_SCRIPT} ;

    echo "cd ${WORKING_DIR} ; " >> ${RUN_PIPELINE_SCRIPT} ;
    
    echo '
if [ -f ${MD5SUM_LOG} ] && [ $(grep FAILED ${MD5SUM_LOG} | wc -l) != 0 ] ; then
    echo "WARNING: Some files did NOT match md5sum, please check the log ${MD5SUM_LOG}. " ; 
    exit -1 ;
fi ' >> ${RUN_PIPELINE_SCRIPT} ;

fi

#### if concat fastq directory is given, then add to config options
if [ ${DO_DOWNLOAD} == true ] || [ ${DO_CONCAT} == true ] ; then

    if [ ${INTERACT} == false ] && [ -z ${DATABASE} ] ; then
	echo "[Error] --download-DB is mandatory option for concatenation. "
	exit -1
    fi
    
    if [ -z "${STORAGE_DIR}" ] ; then
	if [ ${INTERACT} == true ] ; then
	    if [ -z ${DATABASE} ] ; then
		echo -e "[check point] please choose the database by the number : \n  1. EGA \n  2. iRODS \n  3. Amazon S3 \n  4. BGI GeneAn \n  5. FTP Server \n  6. From backup storage \n"
		read line
		case $line in 
		    1 ) DATABASE=${EGA} ;;
		    2 ) DATABASE=${IRODS} ;;
		    3 ) DATABASE=${AMAZON} ;;
		    4 ) DATABASE=${BGI} ;;
		    5 ) DATABASE=${FTP} ;;
		    6 ) DATABASE=${STORAGE} ;;
		esac
	    fi
	    
	    echo "[check point] Please provide the directory of raw data. [enter to continue with default] "
	    read line
	    if [ ! -z ${line} ] ; then
		STORAGE_DIR=${line}
	    fi
	fi
	if  [ -z "${STORAGE_DIR}" ] ; then
	    STORAGE_DIR="${SCRATCH_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}" ;
	fi
    fi
    
    if [ -z "${CONCAT_DIR}" ] ; then
	if [ ${INTERACT} == true ] ; then
	    echo "[check point] Please provide the directory for the concatenation of raw data. [enter to continue with default] "
	    read line
	    if [ ! -z ${line} ] ; then
		CONCAT_DIR=${line}
	    fi
	fi
	if  [ -z "${CONCAT_DIR}" ] ; then
	    CONCAT_DIR="${SCRATCH_CONCAT_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}" ;
	fi
    fi
	
    CONFIG_OPTIONS=" raw_fastq_dir=${STORAGE_DIR} concat_fastq_dir=${CONCAT_DIR}" ;
    
    if [ ! -d "${CONCAT_DIR}" ] ; then
	mkdir -p ${CONCAT_DIR} ;
    fi

    mkdir -p ${WORKING_DIR}/config/ ;
    
    if [ ${INTERACT} == true ] ; then 
	echo "[check point] Please provide the table of samples meta info. if it is possible : [enter to continue]"
	read line
	if [ ! -z ${line} ] ; then
	    cp ${line} ${WORKING_DIR}/config/sample_sheet.tsv ;
	else
	    echo "[check point] Please provide the variant call table : "
	    read line ;
	    if [ ! -z ${line} ] ; then
		cp ${line} ${WORKING_DIR}/config/variant_call_list_${MODE}.tsv ;
	    fi
	fi
    fi
	
    build_concat_cmd ${STORAGE_DIR} ${CONCAT_DIR} ${RUN_PIPELINE_SCRIPT} ;
fi

#########################
#### start pipelline ####
#########################

fastq_dir="${WORKING_DIR}/DNA_samples"
bam_dir="${WORKING_DIR}/bam"

if [ ${DO_PIPELINE} == true ] ; then

    if [ ${DATA_FILETYPE} == ${FASTQ} ] && [ ! -d ${fastq_dir} ] ; then 
	#### if variable of concated sample directory is defined but DNA_samples doesn't exist, then create the DNA_samples directory
	echo "[info] init DNA_samples directory" ; 
	mkdir -p ${fastq_dir} ;
    elif [ ${DATA_FILETYPE} == ${BAM} ] && [ ! -d ${bam_dir} ] ; then 
	#### if bam files are given, but bam directory doesn't exist, then create the directory
	echo "[info] init bam file direcotry" ; 
	mkdir -p ${bam_dir} ;
    fi

    if [ ${DATA_FILETYPE} == ${BAM} ] && [ ! "$(ls ${bam_dir})" ] && [  "$(ls ${BAM_SAMPLES_DIR}/*bam)" ] ; then 
	#### if bam files are given, but bam directory is empty, then link to bam files
	ln -s ${BAM_SAMPLES_DIR}/*bam ${bam_dir} ; 
	if [ "$(ls ${bam_dir}/*bai)" ] ; then
	    ln -s ${BAM_SAMPLES_DIR}/*bai ${bam_dir} ;
	fi
    fi

    #### cnvfacet need the conda env. has to be local, if conda env doesn't exsit then softlink to j_wang 
    if [ DO_CNVFACET == ture ] && [ ! -d ~/.conda/envs/pipeline_GATK_2.1.4_V2 ] && [ ! -d ~/conda/envs/pipeline_GATK_2.1.4_V2 ] && [ ! -d ~/Anaconda3/envs/pipeline_GATK_2.1.4_V2 ] && [ ! -d ~/miniconda3/envs/pipeline_GATK_2.1.4_V2 ] ; then 
	envs_dir=(`conda info | grep "envs directories" `)
	if [ ! -d ${envs_dir[-1]}/pipeline_GATK_2.1.4_V2 ] ; then
	    ln -s /mnt/beegfs/userdata/j_wang/.conda/envs/pipeline_GATK_2.1.4_V2 ${envs_dir[-1]}/pipeline_GATK_2.1.4_V2 ;
	fi
    fi  
fi

if [ ${DO_PIPELINE} == true ] ; then 

    CONFIG_OPTIONS=" samples=${SAMPLES} seq_type=${SEQ_TYPE} mode=${MODE} "

    if [ ${DO_CNVFACET} == true ] || [ ${DO_CLINIC} == true ] ; then
	CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_cnvfacet=True "
    fi
    
    #### if bam directory is not empty, then clean up temporal bam files
    build_pipeline_cmd "${CONFIG_OPTIONS}" ${CONCAT_DIR} ${RUN_PIPELINE_SCRIPT} ;

fi

####################################################
####          oncokb and civic annotations      ####
####################################################

if [ ${DO_CLINIC} == true ] ; then
    # echo "starting oncokb and civic annotations..."
    # 1.  build configuration files
    # example patients.tsv
    # PATIENT_ID      Sex     MSKCC_Oncotree  Project_TCGA_More
    # ST4359          M       SCLC            SCLC
    # ST3259          F       LUAD            LUAD
    # ST4405          M       PRAD            PRAD
    # ST3816          F       HGSOC           OV
    # ST4806          M       BLCA            BLCA

    # config/patients.tsv
    # cat ${PATIENTS_TABLE}
    
    if [ ${INTERACT} == true ] && [ ! -f ${PATIENTS_TABLE} ] ; then
	echo "[check point] Please provide the patients info. table "
	echo "patients table contains at least 4 columns: 'PATIENT_ID', 'Sex', 'MSKCC_Oncotree', 'Project_TCGA_More'"
	echo "
    # example: patients.tsv
    # PATIENT_ID      Sex     MSKCC_Oncotree  Project_TCGA_More
    # ST4359          M       SCLC            SCLC
    # ST3259          F       LUAD            LUAD
    # ST4405          M       PRAD            PRAD
    # ST3816          F       HGSOC           OV
    # ST4806          M       BLCA            BLCA

location of the table: "
	read line
	if [ ! -z ${line} ] ; then
	    cp ${line} ${WORKING_DIR}/config/patients.tsv ;
	    cp ${ANALYSIS_PIPELINE_SRC_DIR}/workflow/config/clinic.yaml ${WORKING_DIR}/config/ ;
	fi
    fi

    build_oncokb_civic_cmd ${RUN_PIPELINE_SCRIPT} ;
fi

###########################
#### backup to storage ####
###########################

#### do backup of all analysis results
BACKUP_TARGETS=('fastq_QC_raw' 'fastq_QC_clean' 'haplotype_caller_filtered' 'annovar' 'mapping_QC' 'cnv_facets' 'facets' 'Mutect2' 'oncotator_maf' 'oncotator_tsv_COSMIC_exom' 'annovar_mutect2')

BACKUP_FASTQ_PWD="${BACKUP_PWD}/${FASTQS_DIR}"
BACKUP_CONCATS_PWD="${BACKUP_PWD}/${CONCATS_DIR}"
BACKUP_BAM_PWD="${BACKUP_PWD}/${BAMS_DIR}"

if [ $DO_BACKUP_RESULTS == true ] ; then
    echo "[info] backup analysis results to storage"
    BACKUP_RESULTS_PWD="${BACKUP_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}"
    for dir in ${BACKUP_TARGETS[@]} ; do
	echo "
mkdir -p ${BACKUP_RESULTS_PWD} ;
rsync -avh --progress ${dir} ${BACKUP_RESULTS_PWD} ; " >> ${RUN_PIPELINE_SCRIPT} ;
    done
fi

#### do backup of fastq raw data
if [ $DO_BACKUP_FASTQ == true ] ; then
    echo "[info] backup raw fastq files to storage"
    BACKUP_FASTQ_PWD="${BACKUP_FASTQ_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}" ;
    echo "
mkdir -p ${BACKUP_FASTQ_PWD} ;
rsync -avh --progress ${STORAGE_DIR} ${BACKUP_FASTQ_PWD} ; " >> ${RUN_PIPELINE_SCRIPT} ;
    if  [ ${DO_BACKUP_RESULTS} == true ] ; then 
	echo "ln -s  ${BACKUP_FASTQ_PWD} ${BACKUP_RESULTS_PWD}/RAW_FASTQ ; " >> ${RUN_PIPELINE_SCRIPT} ; 
    fi
fi

#### do backup of concatenated fastq raw data
if [ $DO_BACKUP_CONCAT == true ] ; then
    echo "[info] backup concat fastq files to storage"
    BACKUP_CONCATS_PWD="${BACKUP_CONCATS_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}" 
    echo "
mkdir -p ${BACKUP_CONCATS_PWD} ;
rsync -avh --progress ${CONCAT_DIR} ${BACKUP_CONCATS_PWD} ; " >> ${RUN_PIPELINE_SCRIPT} ;
    if [ ${DO_BACKUP_RESULTS} == true ] ; then
	echo "ln -s ${BACKUP_CONCATS_PWD} ${BACKUP_RESULTS_PWD}/CONCAT_FASTQ ; " >> ${RUN_PIPELINE_SCRIPT} ;
    fi
fi

#### do backup of bam file
if [ $DO_BACKUP_BAM == true ] ; then
    echo "[info] backup bam files to storage"
    BACKUP_BAM_PWD="${BACKUP_BAM_PWD}/${PROJECT_NAME}/${DATE}_${DATABASE}"
    echo "
mkdir -p ${BACKUP_BAM_PWD} ;
rsync -avh --progress bam ${BACKUP_BAM_PWD} ; " >> ${RUN_PIPELINE_SCRIPT} ;
    if [ ${DO_BACKUP_RESULTS} == true ] ; then
	echo "ln -s ${BACKUP_BAM_PWD} ${BACKUP_RESULTS_PWD}/bam ; " >> ${RUN_PIPELINE_SCRIPT} ;
    fi
fi 

cp ${RUN_PIPELINE_SCRIPT} ${WORKING_DIR} ;
chmod u+x  ${WORKING_DIR}/*sh ;
