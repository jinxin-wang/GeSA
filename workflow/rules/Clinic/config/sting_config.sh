#!/usr/bin/bash

set -e ; 

mkdir -p logs/slurm/ ; 

/mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --latency-wait 50 --rerun-incomplete --config ${CONFIG_OPTIONS} ;
