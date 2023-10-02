rule bam2fastq:
    input:
        bam = "BAM_samples/{sample}.bam",
    output:
        fq1 = "DNA_samples/{sample}_1.fastq.gz",
        fq2 = "DNA_samples/{sample}_2.fastq.gz",
    log:
        "logs/BAM_samples/{sample}.log",
    params:
        queue = "shortq",
        samtools = config["samtools"]["app"],
    threads : 16
    resources:
        mem_mb = 51200
    run:
        shell('{params.samtools} fastq -c 6 -@ {threads} -1 {output.fq1} -2 {output.fq2} -0 /dev/null -s /dev/null -n -F 0x900 {input.bam} 2> {log}')
