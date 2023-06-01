### 1. Description of Flagstat Module
The flagstat module is a part of the samtools package. It is used to generate statistics for BAM files. 
The FLAGstat module is a tool used in bioinformatics for analyzing sequencing data, specifically data generated from high-throughput sequencing technologies such as next-generation sequencing (NGS). The module is typically part of bioinformatics software packages, such as SAMtools, that are used for processing and analyzing sequencing data.

### 2. Description of Interfaces and Dependencies

- Specifications of Input Files
```
bam = "bam/{sample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam"
```

```
bai = "bam/{sample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam.bai"
```
- Ouput Files
```
"mapping_QC/flagstat/{sample}_flagstat.txt"
```
- Genome Reference

- Packages and Versions

### 3. Issues and TODO
