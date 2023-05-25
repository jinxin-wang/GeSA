### 1. Description of Align Module

Align Module typically refers to a computational tool or software module used to align or map sequencing reads to a reference genome.
Researchers may determine where each read came from and how it links to the reference sequence by using the alignment process to determine each read's position and orientation within the reference genome.

### 2. Description of Interfaces and Dependencies

- Specifications of Input Files
1. Reference Genome File: contains the sequence of the reference genome to which the sequencing reads will be aligned. It is typically a FASTA-formatted file 
```
 "human": {
            "index": "/mnt/beegfs/scratch/Lg_PANUNZI/Konstantin/gatk/human_g1k_v37.fasta",
        },
 "mouse": {
            "index":  "/mnt/beegfs/scratch/j_wang/00_Genome_Ref/mm9/NCBIM37_um.fa"
```
2. Sequencing Read File : These files contain the raw or processed sequencing reads that need to be aligned to the reference genome. The reads can be in various formats notably FASTQ (.fastq)
```
fastq = ["DNA_samples_clean/{sample}_1.fastq.gz", "DNA_samples_clean/{sample}_2.fastq.gz"] if config["paired"] == True else "DNA_samples_clean/{sample}_0.fastq.gz"
```
3. Index Files : 

- Ouput Files

1. Alignment Results File : BAM (Binary Alignment/Map) File: A binary version of the SAM file that provides a more compact representation of the alignment results. BAM files are compressed and typically more efficient for storage and processing. They are often used for downstream analysis and visualization.
```
  temp("bam/{sample}.bam")
```
2. Log Files: Text files that capture information about the alignment process, including any warnings, errors, or progress updates. These files can be helpful for troubleshooting and understanding the alignment workflow.
```
"logs/bam/{sample}.bam.log"
```
- Genome Reference

- Packages and Versions

### 3. Issues and TODO

Single-end or paired-end DNA sample mapping using BWA

BWA (Burrows-Wheeler Aligner) is a widely used software package for aligning next-generation sequencing (NGS) data to a reference genome , it supports both single-end and paired-end reads and provides different algorithms tailored for different types of sequencing data
Before mapping the reads, you need to index the reference genome using BWA. This step prepares the reference genome for efficient alignment. 
```
    input:
        fastq = ["DNA_samples_clean/{sample}_1.fastq.gz", "DNA_samples_clean/{sample}_2.fastq.gz"] if config["paired"] == True else "DNA_samples_clean/{sample}_0.fastq.gz",
    output:
        temp("bam/{sample}.bam")
```
The main algorithm implemented in BWA here is :
BWA-MEM: designed for aligning longer reads (e.g., Illumina HiSeq, NovaSeq) to a reference genome.

```
shell:
        "{params.bwa} mem -M -R \"@RG\\tID:bwa\\tSM:{wildcards.sample}\\tPL:ILLUMINA\\tLB:truseq\" -t {threads} {params.index} {input.fastq} | {params.samtools} view -bS - | {params.samtools} sort -@ {threads} - -o {output} 2> {log}"
```
### [The SAM/BAM Format Specification](https://samtools.github.io/hts-specs/SAMtags.pdf)

[Learn bam file format](https://bookdown.org/content/24942ad6-9ed7-44e9-b214-1ea8ba9f0224/learning-the-bam-format.html)

[sam/bam file format explanation](https://genome.sph.umich.edu/wiki/SAM)

[SAM/BAM/CRAM Format](https://learn.gencore.bio.nyu.edu/ngs-file-formats/sambam-format/)
