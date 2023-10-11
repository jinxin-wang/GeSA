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

# source ~/.bashrc
# conda activate /mnt/beegfs/userdata/j_wang/.conda/envs/metaprism_r

# Rscript ~/MetaPRISM/scripts/combined_alterations/workflow/scripts/01.1_aggregate_alterations_across_modalities.R \
Rscript workflow/rules/Clinic/scripts/01.1_aggregate_alterations_across_modalities.R \
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
