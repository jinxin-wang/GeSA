#!/usr/bin/bash

set -e ; 

SAMPLES="human"
SEQ_TYPE="WGS"
MODE="TvN"

CONFIG_OPTIONS="samples=${SAMPLES} seq_type=${SEQ_TYPE} mode=${MODE}"

module load java ;
mkdir -p logs/slurm/ ; 
rm -f bam/*tmp* ;

/mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --latency-wait 50 --rerun-incomplete --config ${CONFIG_OPTIONS} -n ;