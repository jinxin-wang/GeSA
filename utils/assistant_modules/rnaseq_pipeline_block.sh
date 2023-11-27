function format_samples_name {
    
    LOCAL_FASTQ_DIR=$1 ;
    RUN_PIPELINE_SCRIPT=$2 ;
    
    echo "
for fastq in ${LOCAL_FASTQ_DIR}/* ; do
    if [ \$fastq != \${fastq//-/_} ] ; then
        mv \$fastq \${fastq//-/_} ;
    fi 
    
    if [ \$fastq != \${fastq//__/_} ] ; then
        mv \$fastq \${fastq//__/_} ;
    fi 
done " >> ${RUN_PIPELINE_SCRIPT} ;
}

function rnaseq_pipeline {

    LOCAL_FASTQ_DIR=$1 ;
    NFCORE_SAMPLE_SHEET=$2 ;
    RUN_PIPELINE_SCRIPT=$3 ;
    WORKING_DIR=$4 ;

    echo -e "trace.overwrite = true\ndag.overwrite = true" > ${WORKING_DIR}/config/nextflow.config

    echo "
rm -f workflow ;

touch ${RNA_SEQ_PIPELINE_TAG} ;
rnaseq_pipeline_success=\$(grep 'complete' ${RNA_SEQ_PIPELINE_TAG} | wc -l) ;

if [[ \${fusion_pipeline_success} -eq 0 ]] ; then 


fi" >> ${RUN_PIPELINE_SCRIPT}
}

#############################################################################
####                 setup rnaseq analysis pipeline submodule            ####
#############################################################################

if [ ${INTERACT} != false ] && [ ${DO_DOWNLOAD} != true ] && [ ${DO_CONCAT} != true ] ; then
    echo -e "${WARNING}[check point]${ENDC} Do you need to activate and setup nfcore rnafusion pipeline submodule ? [y]/n"
    read line ;
    if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
        DO_PIPELINE=true ; 
	# enable_all_backup ;
    else
    	DO_PIPELINE=false ;
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

if [ ${DO_PIPELINE} == true ] ; then 

    if [ -z ${DATABASE} ] && [ ${INTERACT} != false ] ; then
        DATABASE=$(choose_database) ;
    fi

    if [ ${DO_CONCAT} != true ] && [ ${INTERACT} != false ] && [ -z "${CONCAT_DIR}" ] ; then
        CONCAT_DIR=$(setup_concat_dir ${SCRATCH_FASTQ_PWD} ${PROJECT_NAME} ${DATE} ${DATABASE}) ;
        echo -e "${OKGREEN}[info]${ENDC} The directory for the concatenated data : ${OKGREEN}${CONCAT_DIR}${ENDC}  " ;
    fi    
    
    LOCAL_FASTQ_DIR="fastq" ;
    mkdir -p ${WORKING_DIR}/${LOCAL_FASTQ_DIR} ;

    echo "
mkdir -p ${LOCAL_FASTQ_DIR} ;
if [ -z \"\$(ls ${LOCAL_FASTQ_DIR})\" ] ; then 
    ln -s ${CONCAT_DIR}/*gz ${LOCAL_FASTQ_DIR} ;
fi " >> ${RUN_PIPELINE_SCRIPT} ;

    format_samples_name ${LOCAL_FASTQ_DIR} ${RUN_PIPELINE_SCRIPT} ;
    rnaseq_pipeline ${LOCAL_FASTQ_DIR} ${NFCORE_SAMPLE_SHEET} ${RUN_PIPELINE_SCRIPT} ${WORKING_DIR} ;

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
BACKUP_TARGETS=('some dir') ;

BACKUP_FASTQ_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${FASTQS_DIR}/${DATE}_${DATABASE}"  ; 
BACKUP_CONCATS_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${CONCATS_DIR}/${DATE}_${DATABASE}" ; 
BACKUP_BAM_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${BAMS_DIR}/${DATE}_${DATABASE}" ; 
BACKUP_RESULTS_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${RESULTS_DIR}/${RESULT_BATCH_NAME}" ;



