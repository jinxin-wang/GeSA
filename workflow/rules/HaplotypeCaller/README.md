### 1. Description of HaplotypeCaller Module

The HaplotypeCaller module is a widely used tool in bioinformatics for variant calling from high-throughput sequencing data. It is specifically designed to accurately identify and genotype genetic variations, including single nucleotide polymorphisms (SNPs), insertions, deletions, and larger structural variants . The module employs advanced algorithms and statistical models to make reliable variant calls

Its a combination of local re-assembly, likelihood calculation, and statistical modeling helps to improve the sensitivity and specificity of variant calling, enabling researchers to gain insights into genetic variation and its potential impact on biological processes.

### 2. Description of Interfaces and Dependencies

- Specifications of Input Files
1st to Run somatic variant caller from GATK on all samples :

- Aligned BAM file: The primary input for the HaplotypeCaller module is a Binary Alignment/Map (BAM) file. The BAM file contains the aligned sequencing reads, where each read is mapped to its most likely position in the reference genome.
- The BAI file is always generated alongside the BAM file

```
        bam = "bam/{sample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam",
        bai = "bam/{sample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam.bai",
```
- Ouput Files 
The output of the HaplotypeCaller module is commonly a file in the Variant Call Format (VCF) containing information about the identified genetic variants in the sample . Overall , it provides a comprehensive summary of the detected genetic variants, enabling downstream analyses such as variant annotation, population genetics studies, and identification of potentially disease-causing variants.

As for the TBI file , it is a separate index file that is typically generated for VCF files and is used to enable quick and efficient retrieval of data from large VCF files, particularly for specific genomic regions of interest.

```
        VCF = temp("haplotype_caller_tmp/{sample}_germline_variants_ON_{interval}.vcf.gz"),
        TBI = temp("haplotype_caller_tmp/{sample}_germline_variants_ON_{interval}.vcf.gz.tbi")
```
- Genome Reference

- Packages and Versions

### 3. Issues and TODO
