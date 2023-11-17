source /home/j_wang@intra.igr.fr/Workspace/GSA_AndreiM_Final/utils/assistant_common.sh

if [ ${SEQ_TYPE} == ${WGS} ] || [ ${SEQ_TYPE} == ${WES} ] ; then
    source /home/j_wang@intra.igr.fr/Workspace/GSA_AndreiM_Final/utils/dna_pipeline_block.sh
elif [ ${MODE} == ${RNAFUS} ] ; then
    source /home/j_wang@intra.igr.fr/Workspace/GSA_AndreiM_Final/utils/rnafusion_pipeline_block.sh
elif [ ${MODE} == ${RNASEQ} ] ; then
    source /home/j_wang@intra.igr.fr/Workspace/GSA_AndreiM_Final/utils/rnaseq_pipeline_block.sh
fi
