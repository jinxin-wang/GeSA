import os

if config["do_concat"]: 
    if os.path.isfile(config["sample_sheet"]):
        include: "concat_samplesheet.smk"
    
    elif os.path.isdir(config["raw_fastq_dir"]):
        include: "concat_src_dir.smk"

checkpoint softlink_to_concat_fastq:
    input:
        fastq = expand(config["concat_fastq_dir"] + "/{sample}_{read}.fastq.gz", sample = SAMPLES, read = config["reads"]),
    output:
        targets = expand("DNA_samples/{sample}_{read}.fastq.gz", sample = SAMPLES, read = config["reads"]),
    params:
        queue = "shortq",
    threads: 1
    resources: 
        mem_mb = 5120
    shell:
        "ln -s {input.fastq} DNA_samples ;"

