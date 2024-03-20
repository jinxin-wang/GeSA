rule build_aggregate_sample_table:
    input:
        bilan = annotation_config["bilan_rebuild"],
        sheet = annotation_config["rna_samplesheet"],
        variant = annotation_config["variant_call_table"],
    output:
        sample_table  = annotation_config["general"]["agg_sample"],
    log:
        out = "logs/conf/build_aggregate_sample_table.log",
    params:
        batch      = annotation_config["batch_num"],
        corr_table = annotation_config["params"]["civic"]["corr_table"],
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 4096,
    # conda: "/mnt/beegfs/userdata/j_wang/.conda/envs/python3"
    shell: "module load python ; python3.9 workflow/rules/Clinic/config/scripts/build_aggregate_sample_table.py --bilan {input.bilan} --sheet {input.sheet} --variant {input.variant} --sample_table {output.sample_table} --batch {params.batch} --corr_table {params.corr_table} --out {log.out} "

rule build_tumor_normal_pairs:
    input:
        bilan = annotation_config["bilan_rebuild"],
        variant = annotation_config["variant_call_table"],
    output:
        sample_table   = annotation_config["general"]["tumor_normal_pairs"],
    log:
        out = "logs/conf/build_tumor_normal_pairs.log",
    params:
        batch      = annotation_config["batch_num"],
        corr_table = annotation_config["params"]["civic"]["corr_table"],
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 4096,
    # conda: "/mnt/beegfs/userdata/j_wang/.conda/envs/python3"
    shell: "module load python ; python3.9 workflow/rules/Clinic/config/scripts/build_tumor_normal_pairs.py --bilan {input.bilan} --variant {input.variant} --sample_table {output.sample_table} --batch {params.batch} --corr_table {params.corr_table} --out {log.out} "

rule build_dna_samples_table:
    input:
        bilan = annotation_config["bilan_rebuild"],
        variant = annotation_config["variant_call_table"],
    output:
        sample_table = annotation_config["general"]["dna_samples"]
    log:
        out = "logs/conf/build_dna_samples_table.log",
    params:
        batch      = annotation_config["batch_num"],
        corr_table = annotation_config["params"]["civic"]["corr_table"],
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 4096,
    # conda: "/mnt/beegfs/userdata/j_wang/.conda/envs/python3"
    shell: "module load python ; python3.9 workflow/rules/Clinic/config/scripts/build_dna_samples_table.py --bilan {input.bilan} --variant {input.variant} --sample_table {output.sample_table} --batch {params.batch} --corr_table {params.corr_table} --out {log.out} "

rule build_rna_samples_table:
    input:
        bilan = annotation_config["bilan_rebuild"],
        sheet = annotation_config["rna_samplesheet"],
    output:
        sample_table = annotation_config["general"]["rna_samples"],
    log:
        out = "logs/conf/build_rna_samples_table.log",
    params:
        batch      = annotation_config["batch_num"],
        corr_table = annotation_config["params"]["civic"]["corr_table"],
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 4096,
    # conda: "/mnt/beegfs/userdata/j_wang/.conda/envs/python3"
    shell: "module load python ; python3.9 workflow/rules/Clinic/config/scripts/build_rna_samples_table.py --bilan {input.bilan} --sheet {input.sheet} --sample_table {output.sample_table} --batch {params.batch} --corr_table {params.corr_table} --out {log.out} "
