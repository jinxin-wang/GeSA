## A rule to map single-end or paired-end DNA sample using BWA
rule bwa_map:
    input:
        fastq = ["DNA_samples_clean/{sample}_1.fastq.gz", "DNA_samples_clean/{sample}_2.fastq.gz"] if config["paired"] == True else ["DNA_samples_clean/{sample}_0.fastq.gz"],
    output:
        temp("bam/{sample}.bam")
    log:
        "logs/bam/{sample}.bam.log"
    params:
        queue = lambda w,input: "shortq" if sum([os.path.getsize(fq) for fq in input.fastq])/1024/1024/1024 < 40 else ( "mediumq" if sum([os.path.getsize(fq) for fq in input.fastq])/1024/1024/1024 < 100 else "longq"),
        bwa = config["bwa"]["app"],
        index = config["bwa"][config["samples"]]["index"],
        samtools = config["samtools"]["app"],
        bwa_core_n = 8,
        sam_core_n = 2,
        sam_mem_mb = lambda w, input: 1024 if sum([os.path.getsize(fq) for fq in input.fastq])/1024/1024/1024 < 40 else 4096,
    threads: 12
    resources:
        mem_mb = lambda w, input: 102400 if sum([os.path.getsize(fq) for fq in input.fastq])/1024/1024/1024 < 40 else 204800,
        disk_mb= lambda w, input: sum([os.path.getsize(fq) for fq in input.fastq])/1024/1024 * 3
    shell:
        "rm -f {output}.tmp.*.bam ; "
        "{params.bwa} mem -M -R \"@RG\\tID:bwa\\tSM:{wildcards.sample}\\tPL:ILLUMINA\\tLB:truseq\" -t {params.bwa_core_n} {params.index} {input.fastq} | {params.samtools} view -bS - | {params.samtools} sort -l 0 -m {params.sam_mem_mb}M -@ {params.sam_core_n} - -o {output} 2> {log}"
