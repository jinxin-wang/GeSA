ANALYSIS_PIPELINE_SRC_DIR="/mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline"

source ${ANALYSIS_PIPELINE_SRC_DIR}/utils/assistant_modules/assistant_common.sh

if [ ${SEQ_TYPE} == ${WGS} ] || [ ${SEQ_TYPE} == ${WES} ] ; then
    source ${ANALYSIS_PIPELINE_SRC_DIR}/utils/assistant_modules/dna_pipeline_block.sh
elif [ ${MODE} == ${RNAFUS} ] ; then
    source ${ANALYSIS_PIPELINE_SRC_DIR}/utils/assistant_modules/rnafusion_pipeline_block.sh
elif [ ${MODE} == ${RNASEQ} ] ; then
    source ${ANALYSIS_PIPELINE_SRC_DIR}/utils/assistant_modules/rnaseq_pipeline_block.sh
fi

setup_backup_submodule ;

backup_results ;
backup_raw ;
backup_concat ;

pipeline_complete ;
