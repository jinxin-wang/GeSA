import os

if os.path.isfile(config["sample_sheet"]):
    include: "generate_concat_bash.smk"
    
elif config["do_concat"]: #  and os.path.isdir(config["raw_fastq_dir"]):
    include: "concat_fastq_from_src_dir.smk"

rule softlink_to_concat_fastq:
    input:
        expand(config["concat_fastq_dir"] + "/{sample}_{read}.fastq.gz", sample = NSAMPLE + TSAMPLE, read = config["reads"]),
    output:
        targets = expand("DNA_samples/{sample}_{read}.fastq.gz", sample = NSAMPLE + TSAMPLE, read = config["reads"]),
        # targets = [ "DNA_samples/%s_%s.fastq.gz"%(s,r) for s in NSAMPLE + TSAMPLE for r in config["reads"] ] ,
    params:
        queue = "shortq",
    threads: 1
    resources: 
        mem_mb = 5120
    shell:
        "cd DNA_samples ; "
        "for read in {input} ; do "
        "  ln -s $read . ; "
        "done"
