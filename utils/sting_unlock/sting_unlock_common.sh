#!/usr/bin/bash

#### define colors
OKGREEN='\033[92m'
WARNING='\033[93m'
FAIL='\033[91m'
ENDC='\033[0m'

set -e
trap "exit" INT

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
STING="STING_UNLOCK"

######################################## raw data directories ########################################
IRODS="iRODS"

DO_DOWNLOAD=true
DO_MD5SUM=false

###################### do concatenation of fastq raw data read 1 and 2 ####################################
DO_CONCAT=true

###################### do genome routine analysis ##########################
DO_PIPELINE=true

#### snakemake settings
APP_SNAKEMAKE="/mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake"
SNAKEMAKE_JOBS_NUM=20

#### data file types:
FASTQ="fastq"

DATA_FILETYPE=${FASTQ}

#### samples: [human|mouse], default: human
HUMAN="human"

#### seq type: [WGS|WES], default: WGS
WES="WES"

#### mode: [TvN|TvNp|Tp|T], default: TvN
TvN="TvN"

RNAFUS="RNAfusion"

NFCORE_VERSION_1P2="nfcore_1.2"

#### pipeline default settings: 
SAMPLES="${HUMAN}"
SEQ_TYPE="${WES}"
MODE="${TvN}"

DO_CNVFACET=true
DO_ONCOTATOR=false

#### variant call table 
VAR_TABLE="variant_call_list_${MODE}.tsv"

#### nfcore sample sheet
NFCORE_SAMPLE_SHEET="config/nfcore_fusion_samplesheet.csv"

DO_CLINIC=true

DO_BAM2FASTQ=false

DO_BACKUP=true
DO_BACKUP_FASTQ=true
DO_BACKUP_CONCAT=false
DO_BACKUP_BAM=false
DO_BACKUP_RESULTS=false
DO_CLEAN_UP=false

#### script exec in interactive mode ####
INTERACT=true

#### #### #### #### #### #### #### #### ####
####           define functions         ####
#### #### #### #### #### #### #### #### ####

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

function join_by_char {
  local IFS="$1" ;
  shift ;
  echo "$*" ;
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
	num_fastq_arr=$(cat ${metadata}|wc -l)
	dataset_size=$((${num_fastq_arr}*2))
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
	num_samples_arr=$(wc -l ${bilan_table}) ;
	dataset_size=$((${num_samples_arr}*10)) ;
    fi

    echo -e "DATABASE: ${DATABASE} \nSTORAGE_PATH: ${STORAGE_DIR}\nDATASET_SIZE: ${dataset_size}\n\n" > ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_datasets_metadata: ${metadata}\niRODS_METADATA_SAMPLE_ID: ${coln_sampleid}\niRODS_METADATA_PATH: ${coln_filepath}\n\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_sample_bilan: ${bilan_table}\niRODS_PROJECT_NAMES: ${project_names}\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_BILAN_QUERY_KEY: ${bilan_query_key}\niRODS_DATASET_QUERY_KEY: ${dataset_query_key}\n" >> ${WORKING_DIR}/config/download.yaml
    echo -e "iRODS_bilan_cquery_keys: ${bilan_cquery_keys}\niRODS_dataset_cquery_keys: ${dataset_cquery_keys}\n" >> ${WORKING_DIR}/config/download.yaml
}
			
function prepare_download {

    PROJECT_NAME=$1
    DATABASE=$2
    STORAGE_DIR=$3
    
    case ${DATABASE} in 
    ${IRODS} )
        prepare_download_from_irods ${STORAGE_DIR} ;
        build_download_cmd ${PROJECT_NAME} ${STORAGE_DIR} ${RUN_PIPELINE_SCRIPT} ;; 
    esac

}

function build_download_cmd {
    
    PROJECT_NAME=$1
    STORAGE_DIR=$2
    PIPELINE_SCRIPT=$3
    
    echo "
rm -f workflow ;
ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow workflow ;
touch ${DOWNLOAD_TAG} ;
DOWNLOAD_TAG=\$(grep 'complete' ${DOWNLOAD_TAG} | wc -l) ;
if [ ! -d ${STORAGE_DIR} ] && [ \${DOWNLOAD_TAG} -eq 0 ] ; then 
    echo 'downloading raw data to ${STORAGE_DIR}' ;
    module load java ;
    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ;	
    CONFIG_OPTIONS=' PROJECT_NAME=${PROJECT_NAME} STORAGE_PATH=${STORAGE_DIR} ' ;
    snakemake \\
        --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web \\
        -s workflow/rules/data/download/entry_point.smk \\
        --configfile config/download.yaml \\
        --jobscript workflow/scripts/rules_decorator.sh  \\
        --config \${CONFIG_OPTIONS} && echo 'complete' > ${DOWNLOAD_TAG} ;
    conda deactivate ;
fi " >> ${PIPELINE_SCRIPT} ;

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

if [ ! -d ${CONCAT_DIR} ] && [[ \${concat_success} -eq 0 ]] ; then 
    echo '[info] Starting to concatenate the raw data to directory ${CONCAT_DIR}' ;
    module load java ; 
    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ;
    snakemake \\
        --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web \\
        -s workflow/rules/data/concat/entry_point.smk \\
        --jobscript workflow/scripts/rules_decorator.sh  \\
        --configfile workflow/config/concat.yaml \\
        --config raw_fastq_dir=${STORAGE_DIR} concat_fastq_dir=${CONCAT_DIR} && echo 'complete' > ${CONCAT_TAG} ;
    conda deactivate ;
fi " >> ${PIPELINE_SCRIPT} ;
}

function setup_backup_submodule {
    # if [ ${INTERACT} != false ] && [ ${DO_DOWNLOAD} == false ] && [ ${DO_CONCAT} == false ] && [ ${DO_PIPELINE} == false ] && [ ${DO_CLINIC} == false ] ; then
    if [ ${INTERACT} != false ] ; then
	disable_all_backup ;
	echo -e "${WARNING}[check point]${ENDC} Do you need to activate and setup backup to storage ? [y]/n"
	read line
	if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	    DO_BACKUP=true ;
	else
	    DO_BACKUP=false ;
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

function setup_configuration {
    WORKING_DIR=$1
    bilan=$2
    dataset=$3
    batch=$4

    echo "rm -f workflow ; ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow workflow ; " >> ${RUN_PIPELINE_SCRIPT} ;
    echo "conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ;" >> ${RUN_PIPELINE_SCRIPT} ;
    echo "snakemake \\
        --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web \\
        -s workflow/rules/Clinic/config/sting_unlock_entry_point.smk \\
        --config bilan_table=${bilan} dataset_table=${dataset} batch_num=${batch}  ; " >> ${RUN_PIPELINE_SCRIPT} ;
    echo "conda deactivate ; " >> ${RUN_PIPELINE_SCRIPT} ;
}

#######################################
####           settings            ####
#######################################

echo -e "${WARNING}[check point]${ENDC} Please provide the batch number : "
read batch
if [ -z ${batch} ] ; then
    exit -1 
fi

DATE=${TODAY}
BATCH_POSTFIX="batch${batch}"

PROJECT_NAME=${STING}
SAMPLES=${HUMAN}

DATA_FILETYPE=${FASTQ}

echo -e "${WARNING}[check point]${ENDC} which analysis to do ? \n"
echo -e "1. Human-WES-TvN \n2. Human-RNAfusion ~ nfcore-version 1.2\n"
read line
if [ ! -z ${line} ] ; then
    case ${line} in 
	1 ) SEQ_TYPE=${WES} ; MODE=${TvN} ;;
	2 ) SEQ_TYPE=${RNA} ; MODE=${RNAFUS}; NFCORE_VERSION=${NFCORE_VERSION_1P2};;
	* ) echo "Unknown choice !" ; exit -1 ;;
    esac
fi

RESULT_BATCH_NAME="${DATE}_${SAMPLES}_${SEQ_TYPE}_${MODE}"

if [ ${MODE} == ${RNAFUS} ] && [ ! -z ${NFCORE_VERSION} ] ; then 
    RESULT_BATCH_NAME="${DATE}_${SAMPLES}_${RNAFUS}_${NFCORE_VERSION}" ;
fi

if [ ! -z ${BATCH_POSTFIX} ] ; then
    RESULT_BATCH_NAME="${RESULT_BATCH_NAME}_${BATCH_POSTFIX}" ;
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

echo -e "#!/usr/bin/bash\n\nset -e ; \ntrap 'exit' INT ; \nsource ~/.bashrc ;\n\n" > ${RUN_PIPELINE_SCRIPT}

#################################################
####      Setup Configuration Submodule      ####
#################################################
echo -e "\n\n${WARNING}[check point]${ENDC} Do you need to activate and setup configuration submodule ? [y]/n"
read line
if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
    echo -e "${WARNING}[check point]${ENDC} Please provide the path of bilan excel table : "
    read bilan
    if [ -z ${bilan} ] ; then
	exit -1 
    fi
    
    echo -e "${WARNING}[check point]${ENDC} Please provide the path of dataset table : "
    read dataset
    if [ -z ${dataset} ] ; then
	exit -1 
    fi

    setup_configuration "${WORKING_DIR}" "${bilan}" "${dataset}" "${batch}" ;
fi

############################################
####      Setup Download Submodule      ####
############################################

echo -e "\n\n${WARNING}[check point]${ENDC} Do you need to activate and setup download submodule ? [y]/n"
read line ;
if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
    DO_DOWNLOAD=true ; 
    DO_MD5SUM=true ;
    DO_CONCAT=true ; 
    DO_PIPELINE=true ; 
    # enable_all_backup ;
else
    DO_DOWNLOAD=false ;
fi

if [ ${DO_DOWNLOAD} == true ] ; then

    echo -e "${OKGREEN}[info]${ENDC} setup the download submodule...."

    DATABASE=${IRODS}
    
    if [ ${INTERACT} == true ] && [ ! -f ${WORKING_DIR}/config/download.yaml ] ; then

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


##################################################################################
####      if concat fastq directory is given, then add to config options      ####
##################################################################################
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

