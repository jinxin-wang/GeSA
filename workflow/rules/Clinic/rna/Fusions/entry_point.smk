rule launch_rnafusion_pipeline:
    input:
        profile="/mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web/",
        snakefile="/mnt/beegfs/pipelines/MetaPRISM_RNAseq_Pipeline/workflow/Snakefile",
    output:
        directory("results/nf-core/MultiQC")
    handover: True
    params:
        "--keep-incomplete --rerun-incomplete",
    threads: 4,
    resources:
        queue = "longq",
        mem_mb= 10240,
    conda:
        "/mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake"
    shell:
        "snakemake"
        "  {params} "
        "  --profile {input.profile} "
        "  -s {input.snakefile} "
        "  {output} "
