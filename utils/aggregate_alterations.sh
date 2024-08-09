#!/usr/bin/bash

set -e 

cln="config/clinic.tsv"

cna="aggregate/somatic_cna/somatic_calls_union_ann.tsv.gz"
mut="aggregate/somatic_maf/somatic_calls_union_ann.maf.gz"
fus="results/annotate/calls_fusions_civic_oncokb.tsv.gz"

gen="workflow/resources/clinic/curated/cancer_genes_curated.tsv"
drug="workflow/resources/clinic/drug_tables/Table_Drugs_v7.xlsx"
target_bed="workflow/resources/clinic/target_files/all_targets_intersect_padded_10n.bed"

log="aggregate_alterations_across_modalities.log"

output_best="aggregated_alterations.tsv"
output_all="aggregated_alterations_all.tsv"

TODAY=`date +%Y%m%d`

echo "[check point] Please provide the batch number:"
read batch

agg="/mnt/beegfs/scratch/j_wang/03_Results/STING_UNLOCK/${TODAY}_human_aggregate_batch${batch}"

mkdir -p ${agg} ;

echo "[check point] Please provide the directory of the analysis of wes : "
read wes
if [ -z ${wes} ] ; then
    exit -1 ;
fi

echo "[check point] Please provide the directory of the analysis of rna : "
read rna
if [ -z ${rna} ] ; then
    exit -1 ;
fi

ln -s ${wes}/aggregate ${agg}
ln -s ${rna}/results ${agg}
ln -s ${wes}/config ${agg}

ln -s /mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/workflow ${agg}

# echo "[check point] Please provide the path of the table for patient informations: [enter to continue with default: ${cln} ]"
# read line
# if [ ! -z ${line} ] ; then 
#     cln=${line}
# fi

# echo "[check point] Please provide the path of oncokb and civic annotation results for cna: [enter to continue with default: ${cna} ]"
# read line
# if [ ! -z ${line} ] ; then 
#     cna=${line}
# fi

# echo "[check point] Please provide the path of oncokb and civic annotation results for mut: [enter to continue with default: ${mut} ]"
# read line
# if [ ! -z ${line} ] ; then 
#     mut=${line}
# fi

# echo "[check point] Please provide the path of oncokb and civic annotation results for fus: [enter to continue with default: ${fus} ]"
# read line
# if [ ! -z ${line} ] ; then 
#     fus=${line}
# fi

# cd ${agg}

# Rscript ~/MetaPRISM/scripts/combined_alterations/workflow/scripts/01.1_aggregate_alterations_across_modalities.R \

echo "
#!/usr/bin/bash

set -e ; 
trap 'exit' INT ; 
source ~/.bashrc ;

conda activate /mnt/beegfs/userdata/j_wang/.conda/envs/metaprism_r

Rscript /mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/workflow/rules/Clinic/scripts/01.1_aggregate_alterations_across_modalities.R \
            --cln ${cln} \
            --cna ${cna} \
            --fus ${fus} \
            --mut ${mut} \
            --gen ${gen} \
            --drug ${drug} \
            --target_bed ${target_bed} \
            --log ${log} \
            --output_best ${output_best} \
            --output_all ${output_all} 

echo \"rscript aggregate_alterations_across_modalities.R is done!\"

# module load python ;
conda activate metaprism_python ;
python /mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/workflow/rules/Clinic/scripts/correct_aggregate_samples_name_by_bilan.py ;
python /mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/workflow/rules/Clinic/scripts/batch_analysis_summary.py
conda deactivate ;
# module unload python ; " >> ${agg}/run.sh

chmod +x ${agg}/run.sh ;

echo "Please execute the following commands : "
echo "cd ${agg}"
echo "./run.sh"
