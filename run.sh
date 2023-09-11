#!/bin/bash

module load java

#### samples: [human|mouse], default: human
#### type_seq: [WGS|WES], default: WGS
#### mode: [TvN|TvNp|Tp|T], default: TvN

# /mnt/beegfs/software/snakemake/5.23.0/bin/snakemake -c 'sbatch --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --latency-wait 50 --rerun-incomplete --config samples=human seq_type=WGS mode=TvN

/mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake --cluster 'sbatch --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --latency-wait 50 --rerun-incomplete --config samples=human seq_type=WGS mode=TvN

