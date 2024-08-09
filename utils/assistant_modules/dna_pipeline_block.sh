function prepare_variant_call_table {

    MODE=$1 ;
    WORKING_DIR=$2 ;
    PIPELINE_SCRIPT=$3 ;
    
    VARIANT_CALL_TABLE=${WORKING_DIR}/config/variant_call_list_${MODE}.tsv

    #### if variant call table is given, then cp to current dir, otherwise create an empty table
    echo "
touch ${DNA_PIPELINE_TAG} ;
dna_pipeline_success=\$(grep 'complete' ${DNA_PIPELINE_TAG} | wc -l)

if [[ \${dna_pipeline_success} -eq 0 ]] ; then

  if [ -f ${VARIANT_CALL_TABLE} ] ; then
    echo '[info] variant call table is ready, please check if it is correct. '
    cat ${VARIANT_CALL_TABLE} ;

  else 
    echo '[info] Generating variant call table...'
    cd DNA_samples ; "  >> ${PIPELINE_SCRIPT} ;
	
    if [ ${MODE} == ${TvN} ] || [ ${MODE} == ${TvNp} ] ; then
	echo "
      nsamples=(*_N_1.fastq.gz) ;
      tsamples=(*_T_1.fastq.gz) ;
      cd ${WORKING_DIR} ;

      if [[ \${#nsamples[*]} -gt 1 ]] ; then
          for nsample in \${nsamples[@]} ; do 
     	    nsample=\${nsample/_1.fastq.gz/} ;
 	    tsample=\${nsample/_N/_T} ;
            echo -e \"\${tsample}\t\${nsample}\" >> ${VARIANT_CALL_TABLE} ;
          done 
      fi " >> ${PIPELINE_SCRIPT} ;
	
    elif [ ${MODE} == ${T} ] || [ ${MODE} == ${N} ] || [ ${MODE} == ${Tp} ] ; then
	echo "
    samples=(*1.fastq.gz) ;
    cd ${WORKING_DIR} ;
    for s in \${samples[@]} ; do
      echo \"\${s/_1.fastq.gz/}\" >> ${VARIANT_CALL_TABLE} ;
    done 
    " >> ${PIPELINE_SCRIPT} ;
    fi
    
    echo "
    echo '[info] variant call table is done, please check if it is correct. [ctrl + C to cancel the process if it is NOT correct]'
    cat ${VARIANT_CALL_TABLE} ;
  fi
fi" >> ${PIPELINE_SCRIPT} ;

}

function build_pipeline_cmd {

    CONFIG_OPTIONS="$1"
    DATASOURCE_DIR="$2"
    DATAFILES_TYPE="$3"
    PIPELINE_SCRIPT="$4"
    MODE="$5"
    SAMPLES="$6"

    # echo "====================== debug info start ========================="
    # echo "CONFIG_OPTIONS=${CONFIG_OPTIONS}"
    # echo "DATASOURCE_DIR=${DATASOURCE_DIR}"
    # echo "DATAFILES_TYPE=${DATAFILES_TYPE}"
    # echo "PIPELINE_SCRIPT=${PIPELINE_SCRIPT}"
    # echo "MODE=${MODE}"
    # echo "SAMPLES=${SAMPLES}"
    # echo "====================== debug info end ========================="

    if [ ${DATAFILES_TYPE} == ${FASTQ} ] ; then

        echo 'if [ -z "$(ls DNA_samples)"  ] ; then '  >> ${PIPELINE_SCRIPT} ;
    
        echo "
    for fn in \` find \${DATASOURCE_DIR} -name *gz \` ; do 
        ln -s \${fn} DNA_samples
    done " >> ${PIPELINE_SCRIPT} ;
    
        echo '
    cd DNA_samples ;
    for s in * ; do
        s1=${s//-/_}   ;
        s2=${s1//__/_} ;
        if [ ${s} != ${s2} ] ; then 
           mv ${s} ${s2} ; 
        fi
    done
    cd ..
fi ' >> ${PIPELINE_SCRIPT} ;

	prepare_variant_call_table ${MODE} ${WORKING_DIR} ${RUN_PIPELINE_SCRIPT} ;

    elif [  ${DATAFILES_TYPE} == ${BAM} ] ; then 
	mkdir -p ${bam_dir} ; 
	bam_files=$(find ${DATASOURCE_DIR} -name "*bam") ; 
	bai_files=$(find ${DATASOURCE_DIR} -name "*bai") ;

	if [ ! -z "${bam_files}" ] ; then
	    echo -e "${OKGREEN}[info]${ENDC} starting to identify the bam files: "
	    for f in ${bam_files} ; do
		echo -e "${OKGREEN}[info]${ENDC} ${f} "
		ln -s ${f} ${bam_dir} ;
	    done
	else
	    echo -e "${FAIL}[WARNING]${ENDC} bam files are NOT found ! "
	fi

	if [ ! -z "${bai_files}" ] ; then
	    echo -e "${OKGREEN}[info]${ENDC} starting to identify the following bai files: "
	    for f in ${bai_files} ; do
		echo -e "${OKGREEN}[info]${ENDC} ${f} "		
		ln -s ${f} ${bam_dir} ;
	    done
	else
	    echo -e "${WARNING}[warning]${ENDC} bam files are NOT found ! "	    
	fi

    fi 
    
    echo "
rm -f workflow ;
ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow workflow ;
touch ${DNA_PIPELINE_TAG} ;
dna_pipeline_success=\$(grep 'complete' ${DNA_PIPELINE_TAG} | wc -l) ;

if [[ \${dna_pipeline_success} -eq 0 ]] ; then 
    echo -e '${WARNING}[check point]${ENDC} Please check if the variant call table is correct: [ctrl+C to cancel if it is NOT correct]'
    cat config/variant_call_list_${MODE}.tsv ;

    echo '[info] Starting ${SAMPLES} ${SEQ_TYPE} pipeline ${MODE} mode' ; " >> ${PIPELINE_SCRIPT} ;

    if [ "${SAMPLES}" == "${HUMAN}" ] ; then
	echo '    module load java ; ' >> ${PIPELINE_SCRIPT} ;
    elif [ "${SAMPLES}" == "${MOUSE}" ] ; then
	echo '    module load java/1.8.0_281-jdk ; ' >> ${PIPELINE_SCRIPT} ;
    fi

    echo "
    rm -f bam/*tmp* ;
    ${APP_SNAKEMAKE} \\
        --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' \\
    	--jobs ${SNAKEMAKE_JOBS_NUM} --latency-wait 50 --rerun-incomplete --use-conda \\
        --jobscript workflow/scripts/rules_decorator.sh  \\
    	--config ${CONFIG_OPTIONS} 
    echo 'complete' > ${DNA_PIPELINE_TAG} ;
fi " >> ${PIPELINE_SCRIPT} ;
    
}

function build_oncokb_civic_cmd {

    PIPELINE_SCRIPT=$1
    CLINIC_TAG=$2
    echo '
if [ ! -f config/patients.tsv ] ; then
    echo -e "${WARNING}[check point]${ENDC} please provide patients table" ;
    read line
    if [ -f ${line} ] ; then
        cp ${line} config/patients.tsv
    fi 
fi ' >> ${PIPELINE_SCRIPT}

    echo "
if [ ! -f config/config.yaml ] ; then
   cd config ; ln -s clinic.yaml config.yaml ; cd .. ; 
fi

if [ ! -f config/samples.tsv ] ; then
   cd config ; ln -s dna_samples.tsv samples.tsv ; cd .. ;
fi

rm -f workflow ;
ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow workflow ;
touch ${CLINIC_TAG} ;
clinic_success=\$(grep 'complete' ${CLINIC_TAG} | wc -l) ; 
if [ -f config/patients.tsv ] && [ ${clinic_success} -eq 0 ] ; then " >> ${PIPELINE_SCRIPT}

    echo '
    echo "Starting oncokb and civic annotation" ; 
    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ; 
    ## 2.0 generate configuration files
    snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/config/entry_point.smk  ;
    ## 2.1 mut. oncokb and civic annotations
    snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/mut/TvN/entry_point.smk ;
    ## 2.2 cna. oncokb and civic annotations
    snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/cna/entry_point.smk     ;
    conda deactivate ; ' >> ${PIPELINE_SCRIPT}

    echo "    echo 'complete' > ${CLINIC_TAG} ;
fi" >> ${PIPELINE_SCRIPT}

}

###########################################################################
####             setup dna routine analysis pipeline submodule         ####
###########################################################################

if [ ${INTERACT} != false ] && [ ${DO_DOWNLOAD} != true ] && [ ${DO_CONCAT} != true ] ; then
    echo -e "${WARNING}[check point]${ENDC} Do you need to activate and setup dna routine analysis pipeline submodule ? [y]/n"
    read line ;
    if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	DO_PIPELINE=true ; 
	# enable_all_backup ;
    else
	DO_PIPELINE=false
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

## dna pipeline needs :
##  global: WORKING_DIR
##  global: RUN_PIPELINE_SCRIPT
##  global: DATA_FILETYPE
## STORAGE_DIR
## CONCAT_DIR

fastq_dir="${WORKING_DIR}/DNA_samples"
bam_dir="${WORKING_DIR}/bam"

if [ ${DO_PIPELINE} != false ] ; then

    echo -e "${OKGREEN}[info]${ENDC} start setting up DNA routine analysis pipeline...."

    if [ ${DATA_FILETYPE} == ${FASTQ} ] && [ ! -d ${fastq_dir} ] ; then 
        #### if variable of concated sample directory is defined but DNA_samples doesn't exist, then create the DNA_samples directory
    	echo -e "${OKGREEN}[info]${ENDC} create DNA samples directory" ; 
    	mkdir -p ${fastq_dir} ;
    elif [ ${DATA_FILETYPE} == ${BAM} ] && [ ! -d ${bam_dir} ] ; then 
    	#### if bam files are given, but bam directory doesn't exist, then create the directory
    	echo -e "${OKGREEN}[info]${ENDC} create bam file direcotry" ; 
    	mkdir -p ${bam_dir} ;
    fi

    #### cnvfacet need the conda env. has to be local, if conda env doesn't exsit then softlink to j_wang 
    if [ DO_CNVFACET == ture ] && [ ! -d ~/.conda/envs/pipeline_GATK_2.1.4_V2 ] && [ ! -d ~/conda/envs/pipeline_GATK_2.1.4_V2 ] && [ ! -d ~/Anaconda3/envs/pipeline_GATK_2.1.4_V2 ] && [ ! -d ~/miniconda3/envs/pipeline_GATK_2.1.4_V2 ] ; then 
    	envs_dir=(`conda info | grep "envs directories" `)
    	if [ ! -d ${envs_dir[-1]}/pipeline_GATK_2.1.4_V2 ] ; then
    	    ln -s /mnt/beegfs/userdata/j_wang/.conda/envs/pipeline_GATK_2.1.4_V2 ${envs_dir[-1]}/pipeline_GATK_2.1.4_V2 ;
    	fi
    fi  

    if [ -z ${DATABASE} ] && [ ${INTERACT} != false ] ; then
	DATABASE=$(choose_database) ;
    fi

    if [ -z "${CONCAT_DIR}" ] && [ ${DATA_FILETYPE} == ${FASTQ} ] && [ ${INTERACT} != false ] ; then
	CONCAT_DIR=$(setup_concat_dir ${SCRATCH_FASTQ_PWD} ${PROJECT_NAME} ${DATE} ${DATABASE}) ;
	echo -e "${OKGREEN}[info]${ENDC} The directory for the concatenated data : ${OKGREEN}${CONCAT_DIR}${ENDC}  "
    fi

    if [ -z "${STORAGE_DIR}" ] && [ ${DATA_FILETYPE} == ${BAM} ] && [ ${INTERACT} != false ] ; then
	STORAGE_DIR=$(setup_storage_dir ${SCRATCH_FASTQ_PWD} ${PROJECT_NAME} ${DATE} ${DATABASE}) ;
	CONCAT_DIR="${STORAGE_DIR}"
	# echo "============================ debug info start ================================="
	# echo "STORAGE_DIR=${STORAGE_DIR}"
	# echo "============================ debug info end ================================="
	echo -e "${OKGREEN}[info]${ENDC} The directory for the bam files : ${OKGREEN}${STORAGE_DIR}${ENDC}  "
    fi

    CONFIG_OPTIONS=" samples=${SAMPLES} seq_type=${SEQ_TYPE} mode=${MODE} "

    if [ ${DATA_FILETYPE} == ${BAM} ] ; then
	CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_bam=False do_fastq=False do_qc=False "
    fi
    
    if [ ${INTERACT} != false ] ; then 
        echo -e "${WARNING}[check point]${ENDC} Please confirm if enable cnvfacet submodule: [y]/n "
        read line
        if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then 
            DO_CNVFACET=true
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_cnvfacet=True "
        else
            DO_CNVFACET=false
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_cnvfacet=False "
        fi
    fi

    if [ ${INTERACT} != false ] ; then 
        echo -e "${WARNING}[check point]${ENDC} Please confirm if enable facet submodule: [y]/n "
        read line
        if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then 
            DO_FACET=true
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_facet=True "
	else
            DO_FACET=false
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_facet=False "
        fi
    fi

    if [ ${INTERACT} != false ] ; then 
        echo -e "${WARNING}[check point]${ENDC} Please confirm if enable annovar submodule: [y]/n "
        read line
        if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then 
            DO_ANNOVAR=true
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_annovar=True "
	else
            DO_ANNOVAR=false
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_annovar=False "
        fi
    fi

    if [ ${INTERACT} != false ] ; then 
        echo -e "${WARNING}[check point]${ENDC} Please confirm if enable haplotype submodule: [y]/n "
        read line
        if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then 
            DO_HAPLOTYPE=true
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_haplotype=True "
	else
            DO_HAPLOTYPE=false
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_haplotype=False "
        fi
    fi

    if [ ${INTERACT} != false ] ; then 
        echo -e "${WARNING}[check point]${ENDC} Please confirm if enable QC submodules: [y]/n "
        read line
        if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then 
            DO_QC=true
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_qc=True "
	else
            DO_QC=false
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_qc=False "
        fi
    fi

    if [ ${INTERACT} != false ] ; then         
        echo -e "${WARNING}[check point]${ENDC} Please confirm if enable mutect2 submodule: [y]/n "
        read line ;
        if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then 
            DO_MUTECT2=true ;
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_mutect2=True "
	else 
            DO_MUTECT2=false ;
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_mutect2=False "
        fi
    fi

    if [ ${INTERACT} != false ] ; then         
        echo -e "${WARNING}[check point]${ENDC} Please confirm if enable oncotator submodule: [y]/n "
        read line ;
        if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then 
            DO_ONCOTATOR=true ;
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_oncotator=True "
	else 
            DO_ONCOTATOR=false ;
            CONFIG_OPTIONS=" ${CONFIG_OPTIONS} do_oncotator=False "
        fi
    fi

    # echo "=========================== debug info start ============================="
    # echo "CONFIG_OPTIONS = ${CONFIG_OPTIONS}"
    # echo "CONCAT_DIR = ${CONCAT_DIR}"
    # echo "DATA_FILETYPE = ${DATA_FILETYPE}"
    # echo "RUN_PIPELINE_SCRIPT = ${RUN_PIPELINE_SCRIPT}"
    # echo "MODE = ${MODE}"
    # echo "SAMPLES = ${SAMPLES}"
    # echo "=========================== debug info end  ============================="

    build_pipeline_cmd "${CONFIG_OPTIONS}" ${CONCAT_DIR} ${DATA_FILETYPE} ${RUN_PIPELINE_SCRIPT} ${MODE} ${SAMPLES} ;

    # if  [ ${DATA_FILETYPE} == ${FASTQ} ] ; then 
    #     build_pipeline_cmd "${CONFIG_OPTIONS}" ${CONCAT_DIR} ${FASTQ} ${RUN_PIPELINE_SCRIPT} ${MODE} ;
    # elif [ ${DATA_FILETYPE} == ${BAM} ] ; then 
    #     # build_pipeline_cmd "${CONFIG_OPTIONS} sam2fastq=True " ${STORAGE_DIR} ${BAM} ${RUN_PIPELINE_SCRIPT} ${MODE} ;
    # 	  build_pipeline_cmd "${CONFIG_OPTIONS}" ${STORAGE_DIR} ${BAM} ${RUN_PIPELINE_SCRIPT} ${MODE} ;
    # fi

fi

#######################################################
####         setup oncokb and civic submodule      ####
#######################################################

if [ ${INTERACT} != false ] && [ "${SAMPLES}" == "${HUMAN}" ] && [ "${MODE}" == "${TvN}" ] ; then
    echo -e "${WARNING}[check point]${ENDC} Do you need to activate and setup Oncokb and CIVIC submodule ? [y]/n"
    read line
    if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
	DO_CLINIC=true
    else
	DO_CLINIC=false
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

## dna pipeline needs :
##  global: WORKING_DIR
##  global: RUN_PIPELINE_SCRIPT

if [ ${DO_CLINIC} == true ] ; then

    echo -e "${OKGREEN}[info]${ENDC} start setting up oncokb and civic annotaion submodule...."

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
    
    if [ ${INTERACT} != false ] && [ ! -f ${PATIENTS_TABLE} ] ; then
        echo -e "${WARNING}[check point]${ENDC} Please provide the patients info. table "
        echo "patients table contains at least 4 columns: 'PATIENT_ID', 'Sex', 'MSKCC_Oncotree', 'Project_TCGA_More'"
        echo "
    # example: patients.tsv
    # PATIENT_ID      Sex     MSKCC_Oncotree  Project_TCGA_More
    # ST4359          M       SCLC            SCLC
    # ST3259          F       LUAD            LUAD
    # ST4405          M       PRAD            PRAD
    # ST3816          F       HGSOC           OV
    # ST4806          M       BLCA            BLCA

location of the table: [enter to continue and set the table later, or set the path now]"
        read line
        if [ ! -z ${line} ] && [ -f ${line} ] ; then
            cp ${line} ${WORKING_DIR}/config/patients.tsv ;
        fi
    fi

    cp ${ANALYSIS_PIPELINE_SRC_DIR}/workflow/config/clinic.yaml ${WORKING_DIR}/config/config.yaml ;

    echo -e "${WARNING} [info] don't forget to check if the API token for OncoKB is expired. "

    build_oncokb_civic_cmd ${RUN_PIPELINE_SCRIPT} ${CLINIC_TAG} ;
fi

######################################################
####       setup backup to storage block          ####
######################################################

## Global variables:
## DATE
## MODE
## SAMPLES
## PROJECT_NAME
## DATA_FILETYPE
## WORKING_DIR
## RUN_PIPELINE_SCRIPT

## dna pipeline needs :
##  global: WORKING_DIR
##  global: RUN_PIPELINE_SCRIPT

#### do backup of all analysis results
BACKUP_TARGETS=('config' 'fastq_QC_raw' 'fastq_QC_clean' 'haplotype_caller_filtered' 'annovar' 'mapping_QC' 'cnv_facets' 'facets' "Mutect2_${MODE}" "Mutect2_${MODE}_exom" "oncotator_${MODE}" "oncotator_${MODE}_exom" "oncotator_${MODE}_maf" "oncotator_${MODE}_maf_exom"  "oncotator_${MODE}_tsv_COSMIC"  "oncotator_${MODE}_tsv_COSMIC_exom" 'annovar_mutect2' 'BQSR' 'fastp_reports' 'remove_duplicate_metrics' "annovar_mutect2_${MODE}")

BACKUP_FASTQ_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${FASTQS_DIR}/${DATE}_${DATABASE}" 
BACKUP_CONCATS_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${CONCATS_DIR}/${DATE}_${DATABASE}" 
BACKUP_BAM_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${BAMS_DIR}/${DATE}_${DATABASE}"
BACKUP_RESULTS_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${RESULTS_DIR}/${RESULT_BATCH_NAME}"

# setup_backup_submodule ;

# backup_results ;
# backup_raw ;
# backup_concat ;
# backup_bam ;

# pipeline_complete ;
