rule launch_rnafusion_pipeline:
    input:
        profile="/mnt/beegfs/pipelines/unofficial-snakemake-wrappers/profiles/slurm-web/",
        snakefile="/mnt/beegfs/pipelines/MetaPRISM_RNAseq_Pipeline/workflow/Snakefile",
    output:
        directory("results/nf-core/tools")
    handover: True
    params:
        "--keep-incomplete --rerun-incomplete"
    conda:
        "/mnt/beegfs/pipelines/unofficial-snakemake-wrappers/bigr_snakemake"
    shell:
        "snakemake "
        "{parmams} "
        "--profile {input.profile} "
        "-s {input.snakefile} "
        "{output} "