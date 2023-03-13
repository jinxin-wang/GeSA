## A rule to map single-end or paired-end DNA sample using BWA
rule bwa_map:
    input:
        fastq = ["DNA_samples_clean/{sample}_1.fastq.gz", "DNA_samples_clean/{sample}_2.fastq.gz"] if config["paired"] == True else "DNA_samples_clean/{sample}_0.fastq.gz",
    output:
        temp("bam/{sample}.bam")
    log:
        "logs/bam/{sample}.bam.log"
    params:
        queue = "mediumq",
        bwa = config["bwa"]["app"],
        index = config["bwa"][config["samples"]]["index"],
        samtools = config["samtools"]["app"]
    threads: 16
    resources:
        mem_mb = 51200
    shell:
        "{params.bwa} mem -M -R \"@RG\\tID:bwa\\tSM:{wildcards.sample}\\tPL:ILLUMINA\\tLB:truseq\" -t {threads} {params.index} {input.fastq} | {params.samtools} view -@ {threads} -bS - | {params.samtools} sort -@ {threads} - -o {output} 2> {log}"
