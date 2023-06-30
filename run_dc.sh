#!/bin/bash

#### samples: [human|mouse], default: human
#### type_seq: [WGS|WES], default: WGS
#### mode: [TvN|TvNp|Tp|T], default: TvN

~/.conda/envs/snakemake/bin/snakemake -s workflow/rules/data/irods/entry_point.smk --cluster 'sbatch --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --latency-wait 50 --rerun-incomplete

