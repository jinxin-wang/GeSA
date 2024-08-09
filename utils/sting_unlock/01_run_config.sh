#!/usr/bin/bash

set -e ; 
trap 'exit' INT ; 
source ~/.bashrc ;


rm -f workflow ; ln -s /mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/workflow workflow ; 
# conda activate /mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake ;
# conda activate /mnt/beegfs/userdata/j_wang/.conda/envs/python3 ;
conda activate metaprism_python ;

/mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake \
        --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {resources.queue}' \
        --jobs 20 --latency-wait 50 --rerun-incomplete --use-conda \
        -s workflow/rules/Clinic/config/sting_unlock_entry_point.smk \
        --config bilan_table=/home/j_wang@intra.igr.fr/sting_docs/bilan.xlsx dataset_table=/home/j_wang@intra.igr.fr/sting_docs/metadata_batch6.csv batch_num=17 ; 

# conda deactivate ; 

