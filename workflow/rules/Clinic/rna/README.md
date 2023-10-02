Run this pipeline:

```
snakemake -s entry_point.smk --use-conda --cluster 'sbatch --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20

```

It will launch MatePrism_RNASeq pipeline, which will launch nf-core RNAFusion pipeline.
