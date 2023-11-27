#!/usr/bin/bash

set -e ; 

#### samples: [human|mouse], default: human
HUMAN="human"
MOUSE="mouse"

#### seq type: [WGS|WES], default: WGS
WGS="WGS"
WES="WES"

#### mode: [TvN|TvNp|Tp|T], default: TvN
TvN="TvN"
TvNp="TvNp"
Tp="Tp"
T="T"

#### pipeline default settings: 
SAMPLES="${HUMAN}"
SEQ_TYPE="${WES}"
MODE="${TvN}"

CONFIG_OPTIONS="samples=${SAMPLES} seq_type=${SEQ_TYPE} mode=${MODE}"

module load java/1.8.0_281-jdk ;
mkdir -p logs/slurm/ ; 
rm -f bam/*tmp* ;

/mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --latency-wait 50 --rerun-incomplete --config ${CONFIG_OPTIONS} ;
