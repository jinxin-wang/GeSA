
# In bilan table :
# the joined key - NIP, DATE BIOPSIE, BSP show the resent or another biopsy
# only the batch num relate to the order of including the data to database
    
rule update_bilan:
    input:
        bilan   = annotation_config["bilan_table"],
        dataset = annotation_config["dataset_table"],
    output:
        rebuild = annotation_config["bilan_rebuild"],
    params:
        batch   = annotation_config["batch_num"],
    log:
        out = "logs/conf/rebuild_bilan.log",
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 1024,
    # conda: "/mnt/beegfs/userdata/j_wang/.conda/envs/python3"
    shell: "module load python ; /mnt/beegfs/software/python/3.9.1/bin/python3.9 workflow/rules/Clinic/config/sting_unlock/update_bilan.py --bilan {input.bilan} --dataset {input.dataset} --rebuild {output.rebuild} --batch {params.batch} --out {log.out} "

rule build_variant_call_table:
    input:
        bilan   = annotation_config["bilan_rebuild"],
        dataset = annotation_config["dataset_table"],
    output:
        variant = annotation_config["variant_call_table"],
    params:
        batch   = annotation_config["batch_num"],
    log:
        out = "logs/conf/build_variant_call_table.log",
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 1024,
    # conda: "/mnt/beegfs/userdata/j_wang/.conda/envs/python3"
    shell: "module load python ; /mnt/beegfs/software/python/3.9.1/bin/python3.9 workflow/rules/Clinic/config/sting_unlock/build_variant_call_table.py --bilan {input.bilan} --dataset {input.dataset} --batch {params.batch}  --variant {output.variant} --out {log.out} "

rule build_rna_samplesheet_table:
    input:
        bilan = annotation_config["bilan_rebuild"],
    output:
        sheet = annotation_config["rna_samplesheet"],
    params:
        batch = annotation_config["batch_num"],
    log:
        out = "logs/conf/build_rna_samplesheet_table.log",
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 1024,
    # conda: "/mnt/beegfs/userdata/j_wang/.conda/envs/python3"
    shell: "module load python ; /mnt/beegfs/software/python/3.9.1/bin/python3.9 workflow/rules/Clinic/config/sting_unlock/build_rna_samplesheet_table.py --bilan {input.bilan} --batch {params.batch} --sheet {output.sheet} --out {log.out} "

# In dataset.STINGUNLOCK_batch:
# *'Alias:STING sample number' can be used as foreign identifier of sample
# sampleId or dataset id in datafilePath can be used as an universal unique identifier of sample
# sample can be grouped by patient id
# time stamp for including data in database: dataset id in datafilePath, maybe sampleId works as well, need to check

rule build_dataset_by_bilan:
    input:
        bilan   = annotation_config["bilan_rebuild"],
        variant = annotation_config["variant_call_table"],
        sheet   = annotation_config["rna_samplesheet"],
    output:
        dataset = annotation_config["rebuild_dataset_table"],
    params:
        batch = annotation_config["batch_num"],
    log:
        out = "logs/conf/filter_dataset_by_bilan.log",
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 1024,
    # conda: "/mnt/beegfs/userdata/j_wang/.conda/envs/python3"
    shell: "module load python ; /mnt/beegfs/software/python/3.9.1/bin/python3.9 workflow/rules/Clinic/config/sting_unlock/rebuild_dataset_by_bilan.py --bilan {input.bilan} --variant {input.variant} --sheet {input.sheet} --dataset {output.dataset} --batch {params.batch} --out {log.out} "

