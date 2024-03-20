## A rule to generate fastq quality control on raw fastq
rule fastqc_raw:
    input:
        fastq='DNA_samples/{sample}.fastq.gz'
    output:
        'fastq_QC_raw/{sample}_fastqc.html',
        temp('fastq_QC_raw/{sample}_fastqc.zip')
    log:
        "logs/fastq_QC_raw/{sample}_fastqc.html.log"
    params:    
        queue = "shortq",
        fastqc = config["fastqc"]["app"],
        adapters = config["fastqc"]["adapters"]
    threads : 4
    resources:
        mem_mb = 25600
    shell:
        '{params.fastqc} -t {threads} -a {params.adapters} -o fastq_QC_raw/ {input.fastq} 2> {log}'

## A rule to generate fastq quality control on cleaned fastq
rule fastqc_clean:
    input:
        fastq_clean="DNA_samples_clean/{sample}.fastq.gz",
    output:
        'fastq_QC_clean/{sample}_fastqc.html',
        temp('fastq_QC_clean/{sample}_fastqc.zip')
    log:
        "logs/fastq_QC_clean/{sample}_fastqc.html.log"
    params:    
        queue = "shortq",
        fastqc = config["fastqc"]["app"],
        adapters = config["fastqc"]["adapters"]
    threads : 4
    resources:
        mem_mb = 25600
    shell:
        '{params.fastqc} -t {threads} -a {params.adapters} -o fastq_QC_clean/ {input} 2> {log}'
