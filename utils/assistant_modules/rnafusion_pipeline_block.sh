### nf-core  ####

function nfcore1.2 {

    LOCAL_FASTQ_DIR=$1 ;
    NFCORE_SAMPLE_SHEET=$2 ;
    RUN_PIPELINE_SCRIPT=$3 ;
    WORKING_DIR=$4 ;

    echo -e "trace.overwrite = true\ndag.overwrite = true" > ${WORKING_DIR}/config/nextflow.config

    echo "
rm -f workflow ;

touch ${RNA_FUS_PIPELINE_TAG} ;
fusion_pipeline_success=\$(grep 'complete' ${RNA_FUS_PIPELINE_TAG} | wc -l) ;

if [[ \${fusion_pipeline_success} -eq 0 ]] ; then 

    module load java/12.0.2 ;
    module load singularity/3.4.1 ;
    module load nextflow/22.10.5 ;

    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/shared_install/cf86d417625a66c2fd24c9995cffb88e_ ; 

    nextflow -config config/nextflow.config \
	run /mnt/beegfs/pipelines/nf-core-rnafusion/1.2.0/main.nf \
	-resume \
	--read_length 150 \
	--plaintext_email \
	--monochrome_logs \
	--fastp_trim \
	--fusioninspector_filter \
	--reference_release 97 \
	--genome GRCh38 \
	--arriba  --ericscript  --pizzly  --star_fusion \
	--max_time '720.h' --max_cpus '20' --max_memory '128.GB' \
	--arriba_ref '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded/arriba' \
	--ericscript_ref '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded/ericscript/ericscript_db_homosapiens_ensembl84' \
	--fasta '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded/Homo_sapiens.GRCh38_r97.all.fa' \
	--fusioncatcher_ref '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded/fusioncatcher' \
	--gtf '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded/Homo_sapiens.GRCh38_r97.gtf' \
	--star_index '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/star-index_150bp' \
	--star_fusion_ref '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded/star-fusion/ctat_genome_lib_build_dir' \
	--transcript '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded/Homo_sapiens.GRCh38_r97.cdna.all.fa.gz' \
	--databases '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded/databases' \
	--profile 'singularity' \
	--input '${NFCORE_SAMPLE_SHEET}' \
	--reads '${LOCAL_FASTQ_DIR}/*_R[1-2].fastq.gz' \
	--genomes_base '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded' \
	--outdir 'results/nf-core' \
	--custom_config_base 'config/nextflow.config' \
	--custom_config_version '1.2.0' ;

    conda deactivate ;

fi" >> ${RUN_PIPELINE_SCRIPT}
}

function nfcore2.1 {

    RNA_FUS_PIPELINE_TAG=$1 ;
    NFCORE_SAMPLE_SHEET=$2 ;
    RUN_PIPELINE_SCRIPT=$3 ;
    WORKING_DIR=$4 ;

    echo "
rm -f workflow ;

touch ${RNA_FUS_PIPELINE_TAG} ;
fusion_pipeline_success=\$(grep 'complete' ${RNA_FUS_PIPELINE_TAG} | wc -l) ;
if [[ \${fusion_pipeline_success} -eq 0 ]] ; then 
    module load java/17.0.4.1 ;
    module load singularity/3.6.3 ;
    module load nextflow/21.10.6 ;

    nextflow run /mnt/beegfs/userdata/j_wang/lib/nfcore/rnafusion/2.1.0/main.nf --starindex --genome GRCh38 -profile singularity --outdir ${WORKING_DIR}/results -resume ;
    echo 'complete' > ${RNA_FUS_PIPELINE_TAG} ;
fi " >> ${RUN_PIPELINE_SCRIPT} ;
}

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
done

for fastq in ${LOCAL_FASTQ_DIR}/* ; do
    if [ \$fastq != \${fastq/_1.fastq/_R1.fastq} ] ; then
        mv \$fastq \${fastq/_1.fastq/_R1.fastq} ;
    fi

    if [ \$fastq != \${fastq/_2.fastq/_R2.fastq} ] ; then
        mv \$fastq \${fastq/_2.fastq/_R2.fastq} ;
    fi
done " >> ${RUN_PIPELINE_SCRIPT} ;
}

function generate_nfcore_samplesheet {

    LOCAL_FASTQ_DIR=$1 ;
    NFCORE_SAMPLE_SHEET=$2 ;
    RUN_PIPELINE_SCRIPT=$3 ;
    WORKING_DIR=$4 ;

    echo "
cd ${WORKING_DIR}/${LOCAL_FASTQ_DIR} ;
r1_list=\$(ls *1.fastq.gz) ;
r2_list=\$(ls *2.fastq.gz) ;
cd ${WORKING_DIR} ;

if [ ! -f ${NFCORE_SAMPLE_SHEET} ] ; then 
    for r1 in \${r1_list[@]} ; do
	echo \"\${r1/_R1.fastq.gz/},${LOCAL_FASTQ_DIR}/\${r1},${LOCAL_FASTQ_DIR}/\${r1/_R1.fastq.gz/_R2.fastq.gz},forward\" >> ${NFCORE_SAMPLE_SHEET}
    done
fi

echo -e 'Please check if the ${NFCORE_SAMPLE_SHEET} is correct: [ctrl+C to cancel the pipeline if it is NOT correct] '
cat ${NFCORE_SAMPLE_SHEET}  "  >> ${RUN_PIPELINE_SCRIPT} ;
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
touch ${CLINIC_TAG} ;
clinic_success=\$(grep 'complete' ${CLINIC_TAG} | wc -l) ; 
if [ -f config/patients.tsv ] && [ \${clinic_success} -eq 0 ] ; then " >> ${PIPELINE_SCRIPT}

    echo '
    echo "Starting oncokb and civic annotation" ; 
    rm -f workflow ;
    ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow workflow ;
    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ; 
    ## 2.0 generate configuration files
    snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s workflow/rules/Clinic/config/entry_point.smk  ;
    conda deactivate ; ' >> ${PIPELINE_SCRIPT} ;

    echo '
    rm -f workflow ;
    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ;
    /mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s ~/Workspace/Genome_Sequencing_Analysis_Clinic/workflow/rules/Clinic/rna/nfcore/rnafusion/1.2/entry_point.smk ; 
    conda deactivate ; ' >> ${PIPELINE_SCRIPT} ;

    echo "    echo 'complete' > ${CLINIC_TAG} ;
fi" >> ${PIPELINE_SCRIPT} ;

}

#############################################################################
####             setup nfcore-fusion analysis pipeline submodule         ####
#############################################################################

if [ ${INTERACT} != false ] && [ ${DO_DOWNLOAD} != true ] && [ ${DO_CONCAT} != true ] ; then
    echo -e "${WARNING}[check point]${ENDC} Do you need to activate and setup nfcore rnafusion pipeline submodule ? [y]/n"
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

if [ ${DO_PIPELINE} == true ] ; then 

    if [ -z ${DATABASE} ] && [ ${INTERACT} != false ] ; then
        DATABASE=$(choose_database) ;
    fi

    if [ ${DO_CONCAT} != true ] && [ ${INTERACT} != false ] && [ -z "${CONCAT_DIR}" ] ; then
        CONCAT_DIR=$(setup_concat_dir ${SCRATCH_FASTQ_PWD} ${PROJECT_NAME} ${DATE} ${DATABASE}) ;
        echo -e "${OKGREEN}[info]${ENDC} The directory for the concatenated data : ${OKGREEN}${CONCAT_DIR}${ENDC}  "
    fi    
    
    if [ ${NFCORE_VERSION} == ${NFCORE_VERSION_1P2} ] ; then
        LOCAL_FASTQ_DIR="results/data/fastq" ;
        mkdir -p ${WORKING_DIR}/config ${WORKING_DIR}/${LOCAL_FASTQ_DIR} ;

        echo "
mkdir -p ${LOCAL_FASTQ_DIR} ;
if [ -z \"\$(ls ${LOCAL_FASTQ_DIR})\" ] ; then 
    ln -s ${CONCAT_DIR}/*gz ${LOCAL_FASTQ_DIR} ;
fi " >> ${RUN_PIPELINE_SCRIPT} ;

        format_samples_name ${LOCAL_FASTQ_DIR} ${RUN_PIPELINE_SCRIPT} ;
        generate_nfcore_samplesheet ${LOCAL_FASTQ_DIR} ${NFCORE_SAMPLE_SHEET} ${RUN_PIPELINE_SCRIPT} ${WORKING_DIR} ;
        nfcore1.2 ${LOCAL_FASTQ_DIR} ${NFCORE_SAMPLE_SHEET} ${RUN_PIPELINE_SCRIPT} ${WORKING_DIR} ;

    elif [ ${NFCORE_VERSION} == ${NFCORE_VERSION_2P1} ] ; then
        LOCAL_FASTQ_DIR="data" ;
        mkdir -p ${WORKING_DIR}/${LOCAL_FASTQ_DIR} ;

        echo "
mkdir -p ${LOCAL_FASTQ_DIR} ;
if [ -z \"\$(ls ${LOCAL_FASTQ_DIR})\" ] ; then 
    ln -s ${CONCAT_DIR}/*gz ${LOCAL_FASTQ_DIR} ;
fi " >> ${RUN_PIPELINE_SCRIPT} ;

        format_samples_name ${LOCAL_FASTQ_DIR} ${RUN_PIPELINE_SCRIPT} ;
        generate_nfcore_samplesheet ${LOCAL_FASTQ_DIR} ${NFCORE_SAMPLE_SHEET} ${RUN_PIPELINE_SCRIPT} ${WORKING_DIR} ;
    	nfcore2.1 ${RNA_FUS_PIPELINE_TAG} ${NFCORE_SAMPLE_SHEET} ${RUN_PIPELINE_SCRIPT} ${WORKING_DIR} ;
    fi 
fi



#######################################################
####         setup oncokb and civic submodule      ####
#######################################################

if [ ${INTERACT} != false ] && [ ${NFCORE_VERSION} == ${NFCORE_VERSION_1P2} ] ; then
    echo -e "${WARNING}[check point]${ENDC} Do you need to activate and setup Oncokb and CIVIC submodule ? [y]/n"
    read line ;
    if [ -z ${line} ] || [ ${line,,} == "y" ] || [ ${line,,} == "yes" ] ; then
        DO_CLINIC=true ;
    else
        DO_CLINIC=false ;
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

    cp ${ANALYSIS_PIPELINE_SRC_DIR}/workflow/config/clinic.yaml ${WORKING_DIR}/config/ ;

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
if  [ ${NFCORE_VERSION} == ${NFCORE_VERSION_1P2} ] ; then 
    BACKUP_TARGETS=('some dir') ;
elif [ ${NFCORE_VERSION} == ${NFCORE_VERSION_2P1} ] ; then 
    BACKUP_TARGETS=('some dir') ;
fi

BACKUP_FASTQ_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${FASTQS_DIR}/${DATE}_${DATABASE}"  ; 
BACKUP_CONCATS_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${CONCATS_DIR}/${DATE}_${DATABASE}" ; 
BACKUP_BAM_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${BAMS_DIR}/${DATE}_${DATABASE}" ; 
BACKUP_RESULTS_PWD="${BACKUP_PWD}/${USER^^}/${PROJECT_NAME}/${RESULTS_DIR}/${RESULT_BATCH_NAME}" ;



