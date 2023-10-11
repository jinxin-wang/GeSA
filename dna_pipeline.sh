#!/usr/bin/bash

set -e

#######################################################
####                 PATH CONVENTION               #### 
#######################################################

## Convention: Path should not terminated by /

FASTQS_DIR="01_RawData"
CONCATS_DIR="02_ConcatData"
WORKING_DIR="03_Projects"
BAMS_DIR="04_BamData"

BACKUP_PWD="/mnt/glustergv0/U981/NIKOLAEV/${USER^^}"
SCRATCH_PWD="/mnt/beegfs/scratch/${USER}"

BACKUP_FASTQ_PWD="${BACKUP_PWD}/${FASTQS_DIR}"
BACKUP_CONCAT_PWD="${BACKUP_PWD}/${CONCATS_DIR}"
BACKUP_WORKING_PWD="${BACKUP_PWD}/${WORKING_DIR}"
BACKUP_BAM_PWD="${BACKUP_PWD}/${BAMS_DIR}"

SCRATCH_FASTQ_PWD="${SCRATCH_PWD}/${FASTQS_DIR}"
SCRATCH_CONCAT_PWD="${SCRATCH_PWD}/${CONCATS_DIR}"
SCRATCH_WORKING_PWD="${SCRATCH_PWD}/${WORKING_DIR}"

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

DO_DOWNLOAD=false
DATABASE=${IRODS}

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

GENERAL_OPTS=project-name:,date:,downloadDB:,rawDIR:,workDIR:,pipelineDIR:,backupDIR:,batch-postfix:,interact,unlock,help
DOWNLOAD_OPTS=download,download-configfile:,download-DB:,download-to:,
MD5SUM_OPTS=md5check,md5check-file:,
CONCAT_OPTS=concat,concat-sample-list:,concat-src:,concat-to:
PIPELINE_OPTS=pipeline,clinic,
BACKUP_OPTS=backupALL,backupFASTQ,backupCONCAT,backupBAM,backupRESULTS

LONG_OPTS=${GENERAL_OPTS},${DOWNLOAD_OPTS},${MD5SUM_OPTS},${CONCAT_OPTS},${PIPELINE_OPTS},${BACKUP_OPTS}

OPTS=$(getopt -a -n run_pipeline --options ${SHORT_OPTS} --longoptions ${LONG_OPTS} -- "$@")

eval set -- "$OPTS"

while true ; do
    case "$1" in
	-a | --all )
	    enable_all_backup ; shift ;;
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
	--download-to )
	    FASTQ_SAMPLES_DIR=$2 ; shift 2 ;;
	
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
	    CONCAT_SAMPLES_DIR=$2 ;
	    shift 2 ;;
	
	--pipeline )
	    DO_PIPELINE=true ; shift ;;  
	--pipeline-branch )
	    DO_PIPELINE=true ; shift 2 ;;
	
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

#### General Settings ####
if [ -z ${DATE} ] ; then
    DATE=${TODAY}
fi

if [ -z ${PROJECT_NAME} ] && [ ${INTERACT} == true ] ; then
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
fi

#### default analysis results directory: 
RESULT_BATCH_NAME="${DATE}_${SAMPLES}_${SEQ_TYPE}_${MODE}"

if [ ! -z ${BATCH_POSTFIX} ] ; then
    RESULT_BATCH_NAME="${RESULT_BATCH_NAME}_${BATCH_POSTFIX}"
fi

# if not abs. path, convert rela. path to abs.
if [ -f ${VAR_TABLE} ] & [[ ${VAR_TABLE} != /* ]] ; then
    VAR_TABLE="${PWD}/$VAR_TABLE"
fi

RUN_PIPELINE_SCRIPT="run_pipeline.sh"

echo -e "#!/usr/bin/bash\n\nset -e\n\n" > ${RUN_PIPELINE_SCRIPT}

#######################################
#### init pipelline work directory ####
#######################################

## current directory is where user execute the interactive bash script
CURRENT_DIR="$PWD"

## working directory is where the pipeline store the results to
WORKING_DIR="${SCRATCH_WORKING_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}"

echo "[info] pipeline working directory: ${WORKING_DIR}"

mkdir -p ${WORKING_DIR}/config
cd ${WORKING_DIR} ;

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
    echo "[info] softlink to pipeline directory ${ANALYSIS_PIPELINE_SRC_DIR} " ;
    ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow  ${WORKING_DIR}/workflow ;
fi

if [ ${DO_DOWNLOAD} == true ] ; then
    if [ ! -f config/download.yaml ] ; then
	if [ ${INTERACT} == true ] ; then
	else
	    echo "[info] copy an example of download configuration file to config/ directory"
	    cp workflow/config/download.yaml config/
	fi
    fi
fi

exit 0

if [ ${DO_PIPELINE} == true ] ; then
        
    #### copy the script run.sh to working directory if not in working directory
    # if [ ${PWD} != ${WORKING_DIR} ] ; then 
    #   echo "[info] copy the script to working directory"
    #   cp $0 ${WORKING_DIR}
    # fi
    
    cd ${WORKING_DIR}

    #### if variable of concated sample directory is defined but DNA_samples doesn't exist, then create the DNA_samples directory
    fastq_dir="DNA_samples"
    if [ ! -z "${CONCAT_SAMPLES_DIR}" ] && [ ! -d ${fastq_dir} ] ; then
	echo "[info] init DNA_samples directory" ; 
	mkdir -p ${fastq_dir} ;
    fi

    #### if bam files are given, but bam directory doesn't exist, then create the directory
    bam_dir="bam"
    if [ ! -z "${BAM_SAMPLES_DIR}" ] && [ ! -d ${bam_dir} ] ; then
	echo "[info] init bam file direcotry" ; 
	mkdir -p ${bam_dir} ;
    fi

    #### if bam files are given, but bam directory is empty, then link to bam files
    if [ ! -z "${BAM_SAMPLES_DIR}" ] && [ ! "$(ls ${bam_dir})" ] ; then 
	cd ${bam_dir} ;
	ln -s ${BAM_SAMPLES_DIR}/*bam . ; 
	cd .. ; 
    fi

    #### if variant call table is given, then cp to current dir, otherwise create an empty table
    if [ -f variant_call_list_${MODE}.tsv ] ; then
	echo "[info] variant call table is ready: "
	cat variant_call_list_${MODE}.tsv ;
	
    elif [ -f ${VAR_TABLE} ] ; then
	echo "[info] copy the variant call table to current directory"
	cp ${VAR_TABLE} . ;
	
    elif [ ${MODE} == ${TvN} ] ; then
	echo "[info] Generating variant call table..."
	cd ${FASTQ_SAMPLES_DIR} ;
	echo "[info] samples:  " ;
	ls ;
	nsamples=(*_N) ;
	tsamples=(*_T) ;
	cd - ;
	for ((  i=0; i<${#nsamples[*]}; ++i )) ; do
	    tsam="${tsamples[$i]//_T/}" ;
	    nsam="${nsamples[$i]//_N/}" ;
	    if [[ ${tsam} != ${nsam} ]] ; then
		echo "[warning] tumor sample name ${tsam} DOSE NOT CORRESPOND TO normal sample name ${nsam} !" ;
		disable_all_tasks ;
	    fi
	    echo -e "${tsamples[$i]}\t${nsamples[$i]}" >> variant_call_list_${TvN}.tsv ;
	done

	echo "[info] variant call table is done: "
	cat variant_call_list_${TvN}.tsv ;
	if [ ${INTERACT} == true ] ; then
	    echo "Is this correct? [y/n]"
	    read line
	    if [ ${line,,} == "n"] || [ ${line,,} == "no" ] ; then
		exit -1
	    else
		echo "[info] variant call table is checked."
	    fi
	fi
	
    elif [ ${MODE} == ${T} ] ; then
	echo "[info] Generating variant call table..."
	cd ${FASTQ_SAMPLES_DIR} ;
	echo "[info] samples:  " ;
	ls ;
	tsamples=(*) ;
	cd - ;
	for ((  i=0; i<${#tsamples[*]}; ++i )) ; do
	    echo -e "${tsamples[$i]}" >> variant_call_list_${T}.tsv ;
	done
	echo "[info] variant call table is done: "
	cat variant_call_list_${T}.tsv ;
	if [ ${INTERACT} == true ] ; then
	    echo "Is this correct? [y/n]"
	    read line
	    if [ ${line,,} == "n"] || [ ${line,,} == "no" ] ; then
		exit -1
	    else
		echo "[info] variant call table is checked."
	    fi
	fi
	
    elif [ ${INTERACT} == true ] ; then
	    echo "Please provide the variant call table location: "
	    read VAR_TABLE
	    cp ${VAR_TABLE} variant_call_list_${MODE}.tsv ;
    else
	    echo "[info] init empty variant call table..." ;
	    touch "variant_call_list_${MODE}.tsv" ;
	    disable_all_tasks
    fi

    #### if annotate civic and oncokb, build configuration files
    # if [ DO_CLINIC == true ] ; then
    #	echo "build configuration files for civic and oncokb annotation pipeline "
    # 
    # fi

    #### cnvfacet need the conda env. has to be local, if conda env doesn't exsit then softlink to j_wang 
    if [ DO_CNVFACET == ture] ; then 
	envs_dir=(`conda info | grep "envs directories" `)
	if [ ! -d ${envs_dir[-1]}/pipeline_GATK_2.1.4_V2 ] ; then
	    ln -s /mnt/beegfs/userdata/j_wang/.conda/envs/pipeline_GATK_2.1.4_V2 ${envs_dir[-1]}/pipeline_GATK_2.1.4_V2 ;
	fi
    fi
    
    cd ${CURRENT_DIR}
fi

#########################################
####         Download Raw Data       ####
#########################################

if [ ${DO_DOWNLOAD} == true ] ; then

    if [ ${INTERACT} == true ] ; then
	echo "Downloading from the database ${DATABASE} , [y/n] "
	read line
	if [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	    echo "${DATABASE} OK"
	else
	    echo "Please specifiy the database [iRODS|Amazon S3|EGA|BGI GeneAn]: please choose the number"
	    echo "1. iRODS"
	    echo "2. Amazon S3"
	    echo "3. EGA"
	    echo "4. BGI GeneAn"
	    read line
	    case line in
		"1" )
		    DATABASE="iRODS" ;;
		"2" )
		    DATABASE="S3" ;;
		"3" )
		    DATABASE="EGA" ;;
		"4" )
		    DATABASE="GeneAn" ;;
		* )
		    echo "Non-supported Database. exit"
		    exit -1
	    esac
	fi
    fi
    
    if [ ${INTERACT} == true ] ; then
	echo "Downloading to the directory ${FASTQ_SAMPLES_DIR} , [y/n] "
	read line
	if [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	    echo "OK"
	else
	    echo "Please specifiy the directory: "
	    read FASTQ_SAMPLES_DIR
	fi
    fi
    
    echo "echo 'downloading raw data to ${FASTQ_SAMPLES_DIR}'
    module load java
    mkdir -p ${FASTQ_SAMPLES_DIR} ;
    mkdir -p logs/slurm/ ; 
    CONFIG_OPTIONS=' PROJECT_NAME=${PROJECT_NAME} STORAGE_PATH=${STORAGE_PATH} '
    ${APP_SNAKEMAKE} \
	--cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' \
	--jobs ${SNAKEMAKE_JOBS_NUM} --latency-wait 50 --rerun-incomplete  --use-conda \
	-s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow/rules/data/download/entry_point.smk \
	--config ${CONFIG_OPTIONS} ;  " >> ${RUN_PIPELINE_SCRIPT} ;
fi

exit 0

#########################################
####         verify md5sum code      ####
#########################################

MD5SUM_LOG=${MD5SUM_FILE/.txt/.log}

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

if [ ${DO_MD5SUM} == true ] ; then

    tmpfile=".failed.tmp"

    if [ -f ${MD5SUM_LOG} ] ; then
	echo "[info] md5sum had been verified previously. Ignore"
    else
	echo "[info] verify md5sum"
	check_md5sum_file ;
	md5sum -c ${MD5SUM_FILE} > ${MD5SUM_LOG} ;
    fi
    
    grep "FAILED" ${MD5SUM_LOG} > ${tmpfile}
        
    if [ -s ${tmpfile} ] ; then
	echo "WARNING: Please check the samples, some files did NOT match md5sum" ; 
	cat ${tmpfile} ;
	exit -1
    fi

    rm -f ${tmpfile}
fi

###########################################
####       concat raw fastq files      ####
###########################################

if [ ${DO_CONCAT} == true ] ; then

    cd ${WORKING_DIR}
    
    if [ ${INTERACT} == true ] ; then
	## if concat after download, then there is no need to verify the raw data location
	if [ ${DO_DOWNLOAD} == false ] ; then
	    echo "1. data sheet.tsv"
	    echo "2. raw data directory"
	    read line
	    case line in
		"1" ) 
		    echo "Raw data location is ${FASTQ_SAMPLES_DIR} ? [y/n]" ;
		    read line ;
		    if [ ${line,,} == "n" ] || [ ${line,,} == "no" ] ; then
			echo "Please set the directory for the raw fastq files:" ;
			read FASTQ_SAMPLES_DIR ;
		    fi ;;
		"2" )
		    echo "Raw data location is ${FASTQ_SAMPLES_DIR} ? [y/n]" ;
		    read line ;
		    if [ ${line,,} == "n" ] || [ ${line,,} == "no" ] ; then
			echo "Please set the directory for the raw fastq files:" ;
			read FASTQ_SAMPLES_DIR ;
		    fi ;;
		 *  ) ;;
	    esac
	else
	    CONFIG_OPTIONS=" raw_fastq_dir=${FASTQ_SAMPLES_DIR} "
	fi
	echo "Concat data location is ${CONCAT_SAMPLES_DIR} ? [y/n]" ;
	read line ;
	if [ ${line,,} == "n" ] || [ ${line,,} == "no" ] ; then
	    echo "Please set the directory for the concatenated fastq files: "
	    read CONCAT_SAMPLES_DIR
	fi
    fi
    
    if [ ! -d "${CONCAT_SAMPLES_DIR}" ] ; then
	mkdir -p ${CONCAT_SAMPLES_DIR} ;
    fi
    
    CONFIG_OPTIONS="${CONFIG_OPTIONS} mode=${MODE} concat_fastq_dir=${CONCAT_SAMPLES_DIR} " ;  

    #### TODO ###########################################################################################
    cd "${}" ; 
    ## replace all the special character '-' by '_' in the sample names
    for sn in * ; do
	if grep -q "-" <<< "$sn"; then
	    echo "[info] mv $sn ${sn//-/_} ; "
	    mv $sn ${sn//-/_} ; 
	fi
    done
    cd - ;

    cd ${CURRENT_DIR}

fi

#########################
#### start pipelline ####
#########################

if [ ${DO_UNLOCK} == true] ; then
    cd {WORKING_DIR} ;
    ${APP_SNAKEMAKE} --unlock ;     
    cd {CURRENT_DIR} ;
fi

echo "[info] do pipeline: ${DO_PIPELINE} "
if [ ${DO_PIPELINE} == true ] ; then 

    CONFIG_OPTIONS="samples=${SAMPLES} seq_type=${SEQ_TYPE} mode=${MODE}"

    #### if concat fastq directory is given, then add to config options
    if [ ${DO_CONCAT} == true ] ; then

	if  [ -z "${CONCAT_SAMPLES_DIR}" ] ; then
	    echo "Please set the directory for the concatenated fastq files: "
	    read CONCAT_SAMPLES_DIR
	fi
	
	CONFIG_OPTIONS="${CONFIG_OPTIONS} concat_fastq_dir=${CONCAT_SAMPLES_DIR}" ;
	
	if [ ! -d "${CONCAT_SAMPLES_DIR}" ] ; then
	    mkdir -p ${CONCAT_SAMPLES_DIR} ;
	fi
	
	if [ $DO_CONCAT == true ] ; then
	    
	    CONFIG_OPTIONS="${CONFIG_OPTIONS} do_concat=True raw_fastq_dir=${FASTQ_SAMPLES_DIR}" ; 
	    
	    cd "${CONCAT_SAMPLES_DIR}" ;
	    for sn in * ; do
		if grep -q "-" <<< "$sn"; then
		    echo "[info] mv $sn ${sn//-/_} ; "
		    mv $sn ${sn//-/_} ; 
		fi
	    done
	    cd - ;
	fi
    fi
    
    # echo "CONFIG_OPTIONS=${CONFIG_OPTIONS}"

    if ( [ -d ${fastq_dir} ] || [ -d ${bam_dir} ] ) && [ -f variant_call_list_${MODE}.tsv ] && [ -d workflow ] ; then

	#### if bam directory is not empty, then clean up temporal bam files
	if [ -d ${bam_dir} ] && [ "$(ls ${bam_dir})" ] ; then 
	    rm -f bam/*tmp* ;
	fi
	
	echo "[info] Starting ${SAMPLES} ${SEQ_TYPE} pipeline ${MODE} mode" ;
	module load java ;
	mkdir -p logs/slurm/ ; 
	${APP_SNAKEMAKE} \
	    --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' \
	    --jobs ${SNAKEMAKE_JOBS_NUM} --latency-wait 50 --rerun-incomplete \
	    --config ${CONFIG_OPTIONS} ;
    fi 
    
fi

####################################################
####          oncokb and civic annotations      ####
####################################################

if [ ${DO_CLINIC} == true ] ; then
    echo "starting oncokb and civic annotations..."
    # 1.  build configuration files
    # example patients.tsv
    # PATIENT_ID      Sex     MSKCC_Oncotree  Project_TCGA_More
    # ST4359          M       SCLC            SCLC
    # ST3259          F       LUAD            LUAD
    # ST4405          M       PRAD            PRAD
    # ST3816          F       HGSOC           OV
    # ST4806          M       BLCA            BLCA

    echo "patients informations, expecting 4 columns: 'PATIENT_ID', 'Sex', 'MSKCC_Oncotree', 'Project_TCGA_More'"
    # config/patients.tsv
    cat ${PATIENTS_TABLE}
    if [ ${INTERACT} == true ] ; then
	
    fi
    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake
    # /mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake \
    #     --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {resources.queue}' \
    #     --jobs 20 --latency-wait 50 --rerun-incomplete  --use-conda -s workflow/rules/Clinic/config/entry_point.smk
    snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/config/entry_point.smk 
    # 2.1 mut. oncokb and civic annotations
    snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/mut/TvN/entry_point.smk
    # 2.2 cna. oncokb and civic annotations
    snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/cna/entry_point.smk 
    conda deactivate 
fi

###########################
#### backup to storage ####
###########################

#### do backup of all analysis results
BACKUP_TARGETS=('fastq_QC_raw' 'fastq_QC_clean' 'haplotype_caller_filtered' 'annovar' 'mapping_QC' 'mapping_QC' 'cnv_facets' 'facets' 'Mutect2' 'oncotator_maf' 'oncotator_tsv_COSMIC_exom' 'annovar_mutect2')

if [ $DO_BACKUP_RESULTS == true ] ; then
    echo "[info] backup analysis results to storage"
    for dir in ${BACKUP_TARGETS} ; do
	if [ -d ${dir} ] && [ "$(ls ${dir})" ] ; then 
	    rsync -avh --progress ${dir} ${BACKUP_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME} ;
	fi
    done
fi

#### do backup of fastq raw data
if [ $DO_BACKUP_FASTQ == true ] ; then
    echo "[info] backup raw fastq files to storage"
    rsync -avh --progress ${FASTQ_SAMPLES_BASE_DIR} ${BACKUP_FASTQ_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/ ;
    #### TODO: check md5sum !!!!!!!!!!!!!!!!!!!!!!
    mkdir -p ${BACKUP_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}/RAW_${fastq_dir}/
    ln -s  ${BACKUP_FASTQ_PWD}/${PROJECT_NAME}/${BACKUP_DATE} !$ ;
fi

#### do backup of concatenated fastq raw data
if [ $DO_BACKUP_CONCAT == true ] ; then
    echo "[info] backup concat fastq files to storage"
    rsync -avh --progress ${CONCAT_SAMPLES_DIR}/* ${BACKUP_CONCAT_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/ ;
    mkdir -p ${BACKUP_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}/${fastq_dir}/
    cd !$ ; ln -s ${BACKUP_CONCAT_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/* . ; cd - ;
fi

#### do backup of bam file
if [ $DO_BACKUP_BAM == true ] ; then
    echo "[info] backup bam files to storage"
    rsync -avh --progress ${bam_dir}/* ${BACKUP_BAM_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/ ;
    mkdir -p ${BACKUP_RESULTS_PWD}/${PROJECT_NAME}/${RESULT_BATCH_NAME}/${bam_dir}/
    cd !$ ; ln -s ${BACKUP_BAM_PWD}/${PROJECT_NAME}/${BACKUP_DATE}/
fi 

#########################################
####         clean up scratch        ####
#########################################

if [ $DO_CLEAN_UP == true ] ; then
    echo "[info] remove the working directory"
fi
