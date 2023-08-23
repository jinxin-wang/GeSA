rule rsync_metaprism_rnafusion_workflow:
    input:
        "/mnt/beegfs/pipelines/MetaPRISM_RNAseq_Pipeline"
    output:
        directory("MetaPRISM_RNAseq_Pipeline/workflow"),
    threads: 2
    resources:
        mem_mb=768,
        runtime=10,
        tmpdir="tmp",
    log:
        "logs/setup_metaprism_rnafusion/workflow.log"
    params:
        "-cvrhP",
    conda:
        "metaprism_r"
    shell:
        "rsync {params} {input}/workflow/* {output} > {log} 2>&1"


rule rsync_metaprism_rnafusion_config:
    input:
        sources="/mnt/beegfs/pipelines/MetaPRISM_RNAseq_Pipeline",
        samples=config.get("metaprism_rnafusion_samples", "config/samples.txt")
    output:
        directory("MetaPRISM_RNAseq_Pipeline/config"),
    threads: 2
    resources:
        mem_mb=768,
        runtime=10,
        tmpdir="tmp",
    log:
        "logs/setup_metaprism_rnafusion/config.log"
    params:
        "-cvrhP",
    conda:
        "metaprism_r"
    shell:
        "rsync {params} {input.sources}/config/* {output} > {log} 2>&1 && "
        "rsync {params} {input.samples} {output}/samples.txt >> {log} 2>&1 "

rule link_metaprism_rnafusion_resources:
    input:
        config.get(
            "metaprism_rnafusion_resources_dir", 
            "/mnt/beegfs/userdata/j_wang/METAPRISM/resources"
        )
    output:
        directory("MetaPRISM_RNAseq_Pipeline/resources")
    threads: 1
    resources:
        mem_mb=768,
        runtime=10,
        tmpdir="tmp",
    log:
        "logs/setup_metaprism_rnafusion/resources.log"
    params:
        "-sfr"
    conda:
        "metaprism_r"
    shell:
        "ln {params} {input} {output} > {log} 2>&1"
    

rule link_metaprism_rnafusion_external:
    input:
        config.get(
            "FusionAnnotator",
            "/mnt/beegfs/userdata/j_wang/METAPRISM/"
        )
    output:
        directory("external")
    threads: 1
    resources:
        mem_mb=768,
        runtime=10,
        tmpdir="tmp",
    log:
        "logs/setup_metaprism_rnafusion/external.log"
    params:
        "-sfr"
    conda:
        "metaprism_r"
    shell:
        "ln {params} {input} {output} > {log} 2>&1"


rule run_metaprism_rnafusion:
    input:
        workflow="MetaPRISM_RNAseq_Pipeline/workflow",
        config="MetaPRISM_RNAseq_Pipeline/config",
        external_resources="MetaPRISM_RNAseq_Pipeline/resources",
        external_tools="MetaPRISM_RNAseq_Pipeline/external",
    output:
        directory("MetaPRISM_RNAseq_Pipeline/results"),
    threads: 2
    resources:
        mem_mb=1024 * 8,
        runtime=lambda wildcards, attempt: attempt * 60 * 48,
        tmpdir="tmp",
    handover: True
    conda:
        "metaprism_r"
    shell:
        "snakemake "
        "-s {input.workflow}/Snakefile "
        "--configfile {input.config}/config.yaml "
        "--jobs 20 "
        "--use-conda "
        "--keep-incomplete "
        "--use-envmodules "
        "--keep-going "
        "--local-cores {threads} "
        "--rerun-triggers mtime "
        "--reason "
        "--printshellcmds "
        "--conda-frontend 'mamba'"