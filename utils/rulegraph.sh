#!/bin/bash

/mnt/beegfs/software/snakemake/5.23.0/bin/snakemake -c 'sbatch --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --configfile config.json --jobs 10 --forceall -n --rulegraph | dot -Tpdf > rule.pdf
