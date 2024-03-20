################################################################################
# Example snakemake file that implements the R&D Best Practices for fgbio's
# Fastq -> Filtered Consensus Pipeline
#
# Required software:
#   snakemake (!)
#   bwa
#   samtools v1.14 or higher
#   fgbio v2.0.0 of higher
#   https://github.com/fulcrumgenomics/fgbio/blob/main/docs/best-practice-consensus-pipeline.md
################################################################################

TSAMPLE = []
NSAMPLE = []
FASTQ   = []

fname   = "variant_call_list.tsv"
genome  = "/mnt/beegfs/scratch/Lg_PANUNZI/Konstantin/gatk/human_g1k_v37.fasta"

if os.path.isfile(fname):
    with open(fname,'r')  as SAMPLE_INPUT_LIST: 
        for line in SAMPLE_INPUT_LIST :
            tmp = line.strip().split('\t')
            tsample = tmp[0]
            TSAMPLE.append(tsample)
            # FASTQ.append(tsample+"_R1")
            # FASTQ.append(tsample+"_R2")
            if len(tmp) == 2:
                nsample = tmp[1]
                NSAMPLE.append(nsample)
                # FASTQ.append(nsample+"_R1")
                # FASTQ.append(nsample+"_R2")
else:
    TSAMPLE, PAIRED = glob_wildcards("DNA_samples/{tsample,.+}_R{paired,[012]}.fastq.gz")

print(TSAMPLE)

wildcard_constraints:
    samples = '|'.join([re.escape(x) for x in TSAMPLE + NSAMPLE])

# Since both rules can generate a uBam...
ruleorder: call_consensus_reads > fastq_to_ubam

rule all:
    input:
        expand("bam/{sample}.cons.filtered.bam", sample=TSAMPLE+NSAMPLE),
        # expand("cbam/{sample}.cons.mapped.sort.bam", sample=TSAMPLE+NSAMPLE),

rule fastq_to_ubam:
    """Generates a uBam from R1 and R2 fastq files."""
    input:
        r1  = "DNA_samples/{sample}_R1.fastq.gz",
        r2  = "DNA_samples/{sample}_R2.fastq.gz",
    output:
        bam = "ubam/{sample}.unmapped.bam"
    params:
        rs  = "3M2S146T",
    resources:
        mem_gb = 64
    log:
        "logs/{sample}.unmapped.log"
    shell:
        " fgbio -Xmx64g --compression 1 --async-io FastqToBam "
        "   --input {input.r1} {input.r2} "
        "   --read-structures {params.rs} {params.rs} "
        "   --sample {wildcards.sample} "
        "   --library  {wildcards.sample} "
        "   --output {output.bam} 2> {log} "

rule map_ubam:
    """Takes an unmapped BAM and generates an aligned BAM using bwa and ZipperBams."""
    input:
        bam = "ubam/{prefix}.unmapped.bam",
    output:
        bam = "ubam/{prefix}.mapped.bam"
    params:
        ref = genome
    threads: 16
    resources:
        mem_gb = 64
    log:
        "logs/align_bam.{prefix}.log"
    shell:
        " samtools fastq {input.bam} "
        " | bwa-mem2 mem -t {threads} -p -K 150000000 -Y {params.ref} - "
        " | fgbio -Xmx48g --compression 1 --async-io ZipperBams "
        "     --unmapped {input.bam} "
        "     --ref {params.ref} "
        "     --output {output.bam} "
        " 2> {log}"

rule group_reads:
    """Group the raw reads by UMI and position ready for consensus calling."""
    input:
        bam   = "ubam/{sample}.mapped.bam",
    output:
        bam   = "gbam/{sample}.grouped.bam",
        stats = "hist/{sample}.grouped-family-sizes.txt",
    params:
        allowed_edits = 1,
    threads: 16
    resources:
        mem_gb = 64
    log:
        "logs/{sample}.grouped.log"
    shell:
        "fgbio -Xmx64g --compression 1 --async-io GroupReadsByUmi "
        "  --input {input.bam} "
        # "  --strategy paired "
        "  --strategy adjacency "
        "  --edits {params.allowed_edits} "
        "  --output {output.bam} "
        "  --family-size-histogram {output.stats} "
        "  2> {log} "

rule call_consensus_reads:
    """Call consensus reads from the grouped reads."""
    input:
        bam = "gbam/{sample}.grouped.bam",
    output:
        bam = "cbam/{sample}.cons.unmapped.bam",
    params:
        min_reads = 1,
        min_base_qual = 20,
    threads: 16
    resources:
        mem_gb = 64
    log:
        "logs/bam/call_consensus_reads.{sample}.log"
    shell:
        "fgbio -Xmx64g --compression 1 CallMolecularConsensusReads "
        "  --input {input.bam} "
        "  --output {output.bam} "
        "  --min-reads {params.min_reads} "
        "  --min-input-base-quality {params.min_base_qual} "
        "  --threads {threads} "
        "  2> {log}"

rule remap_consensus_reads:
    input: 
        bam = "cbam/{sample}.cons.unmapped.bam",
    output:
        bam = "cbam/{sample}.cons.mapped.bam",
    params:
        ref = genome
    threads: 16
    resources:
        mem_gb = 64
    log:
        "logs/bam/{sample}.cons.mapped.log"
    shell:
        " samtools fastq {input.bam} "
        " | bwa-mem2 mem -t {threads} -p -K 150000000 -Y {params.ref} - "
        " | fgbio -Xmx48g --compression 1 --async-io ZipperBams "
        "     --unmapped {input.bam} "
        "     --ref {params.ref} "
        "     --output {output.bam} "
        "     --tags-to-reverse Consensus "
        "     --tags-to-revcomp Consensus "
        " 2> {log}"
        
rule filter_consensus_reads:
    """Filters the consensus reads and then sorts into coordinate order."""
    input:
        bam = "cbam/{sample}.cons.mapped.bam",
        ref = genome,
    output:
        bam = "bam/{sample}.cons.filtered.bam",
    params:
        min_reads = 1,
        min_base_qual = 30,
        max_error_rate = 0.3
    threads: 8
    resources:
        mem_gb = 64
    log:
        "logs/filter_consensus_reads.{sample}.log"
    shell:
        " fgbio -Xmx64g --compression 0 FilterConsensusReads "
        "   --input {input.bam} "
        "   --output /dev/stdout "
        "   --ref {input.ref} "
        "   --min-reads {params.min_reads} "
        "   --min-base-quality {params.min_base_qual} "
        "   --max-base-error-rate {params.max_error_rate} "
        " | samtools sort --threads {threads} -o {output.bam} "
        " 2> {log} "

rule sort_consensus_reads:
    input:
        "cbam/{sample}.cons.mapped.bam"
    output:
        "cbam/{sample}.cons.mapped.sort.bam"
    log:
        "logs/bam/{sample}.cons.mapped.sort.log"
    threads: 16
    params:
        queue = "shortq",
    resources: 
        mem_gb = 64,
    shell:
        "samtools sort --threads {threads} -o {output} -O bam {input} "

