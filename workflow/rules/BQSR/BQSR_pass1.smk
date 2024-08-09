## A rule to remove duplicated readswith picard, will run only if REMOVE_DUPLICATES is set to True in the configuation file
if config["remove_duplicates"] == True :
    rule remove_duplicate:
        input:
            bam = "bam/{sample}.bam"
        output:
            bam = temp("bam/{sample}.nodup.bam"),
            metrics = "remove_duplicate_metrics/{sample}.nodup.metrics"
        threads : 4
        resources:
            mem_mb = 81920
        params:
            queue = lambda w,input: "shortq" if os.path.getsize(input.bam)/1024/1024/1024 < 120 else "mediumq",
            # gatk  = config["gatk"]["app"],
            gatk = config["gatk"][config["samples"]]["app"],
        log:
            "logs/remove_duplicate_metrics/{sample}.nodup.log"
        shell:
            "{params.gatk} --java-options \"-Xmx75g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" MarkDuplicates --INPUT {input.bam} --REMOVE_DUPLICATES true --OUTPUT {output.bam} --METRICS_FILE {output.metrics} 2> {log}"

## A rule to generate bam index with samtools
rule indexbam_before_recal:
    input:
        bam = "bam/{sample}.nodup.bam" if config["remove_duplicates"] == True else "bam/{sample}.bam",
    output:
        bai = temp("bam/{sample}.nodup.bam.bai") if config["remove_duplicates"] == True else temp("bam/{sample}.bam.bai"),
    params:
        queue    = "shortq",
        samtools = config["samtools"]["app"],
    threads : 1
    resources:
        mem_mb = 10240
    log:
        "logs/bam/{sample}.bam.bai.log"
    shell:
        # "{params.samtools} index -@ {threads} {input} 2> {log}"
        "{params.samtools} index {input} 2> {log}"

## A rule to do Base Quality Score Recalibration (BQSR) - first pass, GATK BaseRecalibrator
rule base_recalibrator_pass1:
    input:
        bam = "bam/{sample}.nodup.bam" if config["remove_duplicates"] == True else "bam/{sample}.bam",
        bai = "bam/{sample}.nodup.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.bam.bai",
    output:
        "BQSR/{sample}_BQSR_pass1.table"
    params:
        queue = lambda w,input: "mediumq" if os.path.getsize(input.bam)/1024/1024/1024 < 200 else 'longq',
        # gatk = config["gatk"]["app"],
        gatk = config["gatk"][config["samples"]]["app"],
        target_interval = config["gatk"][config["samples"]]["target_interval"],
        index           = config["gatk"][config["samples"]]["genome_fasta"],
        gnomad_ref      = config["gatk"][config["samples"]]["gnomad_ref"],
    log:
        "logs/BQSR/{sample}_BQSR_pass1.log"
    threads: 1
    resources:
        mem_mb = 51200
    shell:
        "{params.gatk} --java-options \"-Xmx40g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" BaseRecalibrator "
        " -R {params.index}"
        " {params.target_interval}"
        " --known-sites {params.gnomad_ref}"
        " -I {input.bam}"
        " -O {output} 2> {log}"

## A rule to do Base Quality Score Recalibration (BQSR) - first pass, GATK ApplyBQSR
rule apply_bqsr_pass1:
    input:
        bam = "bam/{sample}.nodup.bam" if config["remove_duplicates"] == True else "bam/{sample}.bam",
        bai = "bam/{sample}.nodup.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.bam.bai",
        recal_file = "BQSR/{sample}_BQSR_pass1.table"
    output:
        temp("bam/{sample}.nodup.recal.beforeReformat.bam") if config["remove_duplicates"] == True else temp("bam/{sample}.recal.beforeReformat.bam")
    params:
        queue = lambda w,input: "mediumq" if os.path.getsize(input.bam)/1024/1024/1024 < 50 else 'longq',
        # gatk  = config["gatk"]["app"],
        gatk = config["gatk"][config["samples"]]["app"],
        index = config["gatk"][config["samples"]]["genome_fasta"],
    log:
        "logs/BQSR/{sample}_ApplyBQSR_pass1.log"
    threads: 1
    resources:
        mem_mb = 51200
    shell:
        "{params.gatk} --java-options \"-Xmx40g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp -XX:+UseParallelGC -XX:ParallelGCThreads={threads} \" ApplyBQSR "
        " --create-output-bam-index false"
        " -R {params.index}"
        " --bqsr-recal-file {input.recal_file}"
        " -I {input.bam}"
        " -O {output} 2> {log} "

## A rule to reformat bam after Base Quality Score Recalibration (BQSR) - with samtools (save a lot of space)
rule reformat_bam:
    input:
        bam = "bam/{sample}.nodup.recal.beforeReformat.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.beforeReformat.bam",
    output:
        "bam/{sample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam"
    log:
        "logs/bam_reformat/{sample}_reformat.log"
    params:
        queue = lambda w,input: "shortq" if os.path.getsize(input.bam)/1024/1024/1024 < 50 else 'mediumq',
        samtools = config["samtools"]["app"],
    threads: 4
    resources:
        mem_mb = 20480
    shell:
        "{params.samtools} view -@ {threads} -b -h -o {output} {input.bam}"
        
## A rule to generate bam index with samtools
rule indexbam_after_recal:
    input:
        bam = "bam/{sample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam"
    output:
        bai = "bam/{sample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam.bai"
    params:
        queue = "shortq",
        samtools = config["samtools"]["app"],
    threads : 1
    resources:
        mem_mb = 10240
    log:
        "logs/bam/{sample}.bam.bai.log"
    shell:
        # "{params.samtools} index -@ {threads} {input} 2> {log}"
        "{params.samtools} index {input} 2> {log}"

        
ruleorder: indexbam_after_recal > indexbam_before_recal

