rule sort_bam:
    input:
        bam = "BAM_samples/{sample}.bam",
    output:
        sbam= temp("BAM_samples/{sample}.sorted.bam"),
    log:
        "logs/BAM_samples/{sample}.sorted.log",
    params:
        queue = "shortq",
    threads : 4
    resources:
        mem_mb = 20480
    run:
        shell('module load samtools ; samtools sort -u -@ {threads} -m 4G -n {input.bam} -o {output.sbam} ; ')

rule bam2fastq:
    input:
        bam = "BAM_samples/{sample}.sorted.bam",
    output:
        fq1 = temp("DNA_samples/{sample}_1.fastq"),
        fq2 = temp("DNA_samples/{sample}_2.fastq"),
        singleton = temp("DNA_Singleton_sample/{sample}.fastq"),
    log:
        "logs/BAM_samples/{sample}.log",
    params:
        queue = "shortq",
        # samtools = config["samtools"]["app"],
        targets  = config["sam2fastq"]["targets"],
    threads : 1
    resources:
        mem_mb = 10240
    run:
        # shell('{params.samtools} fastq -c 6 -@ {threads} -1 {output.fq1} -2 {output.fq2} -0 /dev/null -s /dev/null -n -F 0x900 {input.bam} 2> {log}')
        if os.path.isfile(params.targets):
            shell('module load samtools ; samtools view -b -L {params.targets} {input.bam} | samtools fastq -c 0 -1 {output.fq1} -2 {output.fq2} -s {output.singleton} -n - 2> {log}')
            # shell('module load bedtools ; {params.samtools} view -b -L {params.targets} {input.bam} | bedtools bamtofastq -fq {output.fq1} -fq2 {output.fq2} -i - 2> {log}')
        else:
            shell('module load samtools ; samtools fastq -c 0 -1 {output.fq1} -2 {output.fq2} -s {output.singleton} -n {input.bam} 2> {log}')
            # shell('module load bedtools ; bedtools bamtofastq -fq {output.fq1} -fq2 {output.fq2} -i {input.bam} 2> {log}')


from snakemake.utils import min_version
min_version("6.0")

use rule compr_with_gzip_abstract as gzip_fq1 with:
    input:
        "DNA_samples/{sample}_1.fastq",
    output:
        "DNA_samples/{sample}_1.fastq.gz",

use rule compr_with_gzip_abstract as gzip_fq2 with:
    input:
        "DNA_samples/{sample}_2.fastq",
    output:
        "DNA_samples/{sample}_2.fastq.gz",
