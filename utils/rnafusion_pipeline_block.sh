### nf-core  ####

function nfcore1.2 {

    LOCAL_FASTQ_DIR=$1 ;
    NFCORE_SAMPLE_SHEET=$2 ;
    RUN_PIPELINE_SCRIPT=$3 ;
    WORKING_DIR=$4 ;

    echo -e "trace.overwrite = true\ndag.overwrite = true" > ${WORKING_DIR}/config/nextflow.config

    echo "
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
    --input ${NFCORE_SAMPLE_SHEET} \
    --reads ${LOCAL_FASTQ_DIR}/*_R[1-2].fastq.gz \
    --genomes_base '/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded' \
    --outdir 'results/nf-core' \
    --custom_config_base 'config/nextflow.config' \
    --custom_config_version '1.2.0' ; " >> ${RUN_PIPELINE_SCRIPT}
}

function nfcore2.3 {
    echo "TODO nfcore 2.3"
}

# function ln2workflow {
#     #### if workflow is not ln to src, then create a softlink
#     if [ ! -d workflow ] ; then
# 	if [ ${INTERACT} == true ] ; then
# 	    echo "Directory of pipeline is ${ANALYSIS_PIPELINE_SRC_DIR} : [y/n] "
# 	    read line
# 	    if [ ${line,,} == "n" ] || [ ${line,,} == "no" ] ; then
# 		echo "Please specify the directory of pipeline: "
# 		read ANALYSIS_PIPELINE_SRC_DIR
# 	    fi
# 	fi
# 	echo "[info] softlink to pipeline directory ${ANALYSIS_PIPELINE_SRC_DIR} " ;
# 	ln -s ${ANALYSIS_PIPELINE_SRC_DIR}/workflow .
#     fi
# }

#######################################
#### init pipelline work directory ####
#######################################

mkdir -p ${WORKING_DIR}

if [ ${DO_PIPELINE} == true ] ; then

    # ln2workflow
    
    #### copy the script run.sh to working directory if not in working directory
    if [ ${PWD} != ${WORKING_DIR} ] ; then 
	echo "[info] copy the script to working directory"
	cp $0 ${WORKING_DIR}
    fi
    
    cd ${WORKING_DIR}

fi


echo "[info] do pipeline: ${DO_PIPELINE} "

if [ ${DO_PIPELINE} == true ] ; then 

    local_fastq_dir="results/data/fastq"
    
    source ~/.bashrc
    conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/shared_install/cf86d417625a66c2fd24c9995cffb88e_
    echo "conda env ativated"

    cd ${WORKING_DIR} 

    mkdir -p config ${local_fastq_dir} ;
    if [ ! "$(ls ${local_fastq_dir})" ] ; then 
	ln -s ${CONCAT_SAMPLES_DIR}/*gz ${local_fastq_dir} ;
    fi
    
    for fastq in `ls ${local_fastq_dir}/*` ; do
	echo "rename $fastq "
	if [ $fastq != ${fastq/_1.fastq/_R1.fastq} ] ; then
	    mv $fastq ${fastq/_1.fastq/_R1.fastq} 
	fi
	if [ $fastq != ${fastq/_1.fastq/_R2.fastq} ] ; then
	    mv $fastq ${fastq/_2.fastq/_R2.fastq} 
	fi
    done

    cd ${local_fastq_dir}
    r1_list=`ls *_R1.fastq.gz`
    r2_list=`ls *_R2.fastq.gz`
    cd ${WORKING_DIR}

    if [ ! -f ${NFCORE_SAMPLE_SHEET} ] ; then 
	for r1 in ${r1_list} ; do
	    echo "${r1/_R1.fastq.gz/},${local_fastq_dir}/${r1},${local_fastq_dir}/${r1/_R1.fastq.gz/_R2.fastq.gz},forward" >> ${NFCORE_SAMPLE_SHEET}
	done
    fi

    echo "sample_sheet.csv: "
    cat ${NFCORE_SAMPLE_SHEET}

    if [ "$(ls ${local_fastq_dir})" ] && [ -f ${NFCORE_SAMPLE_SHEET} ] ; then
	if [  ${NFCORE_VERSION} == "1.2" ] ; then
            echo "Looding modules for nfore "
	    nfcore_load_module
	    echo "starting nfcore ${NFCORE_VERSION} "
	    nfcore1.2
	elif [  ${NFCORE_VERSION} == "2.3" ] ; then
	    nfcore2.3
	fi
    fi 
    cd "${CURRENT_DIR}"
fi



#### civic and oncoKB ####

conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake

/mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake --profile /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web -s ~/Workspace/Genome_Sequencing_Analysis_Clinic/workflow/rules/Clinic/rna/nfcore/rnafusion/1.2/entry_point.smk 


### backup results #### 


