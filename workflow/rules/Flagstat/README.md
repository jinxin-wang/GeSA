### 1. Description of Flagstat Module

The FLAGstat module is a tool used in bioinformatics for analyzing sequencing data, specifically data generated from high-throughput sequencing technologies such as next-generation sequencing (NGS). The module is typically part of bioinformatics software packages, such as SAMtools, that are used for processing and analyzing sequencing data.

 the FLAGstat module was created in order to offer statistics and information regarding the alignment of sequencing reads to a reference genome. It accepts as input a file in the Sequence Alignment/Map (SAM) format, which includes the sequence, mapping position, and alignment quality information regarding the alignment of reads to a reference genome.

### 2. Description of Interfaces and Dependencies

- Specifications of Input Files

The input file for the FLAGstat module is typically a BAM (Binary Alignment/Map) file as the BAM file is a binary version of the SAM file that is more compact and allows for efficient storage and processing of alignment data.
The Flagstat module will analyze the alignment records stored in the BAM file and calculate various statistics, as described earlier.

```
bam = "bam/{sample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam"
```
The BAI file is generated alongside the BAM file when using tools like SAMtools or Picard to convert SAM to BAM format. the BAI file as an input can improve the performance and efficiency of the FLAGstat module, particularly when dealing with large BAM files as helps in quickly accessing specific regions of interest within the BAM file. 

```
bai = "bam/{sample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam.bai"
```
- Ouput Files

The output file of the FLAGstat module is typically a text file that contains the calculated statistics and summary of the sequencing data. 
```
"mapping_QC/flagstat/{sample}_flagstat.txt"
```
- Genome Reference

FLAGstat module itself does not require the genome reference as an input, the alignment process that generates the BAM file relies on the reference genome

- Packages and Versions

### 3. Issues and TODO
