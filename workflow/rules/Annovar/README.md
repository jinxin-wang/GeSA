### 1. Description of Annovar Module

  The Annovar module is a bioinformatics tool commonly used in genomic research and analysis.
The main purpose of Annovar, which stands for "Annotate Variation," is to annotate genetic variants found in high-throughput sequencing data.
The module takes input in the form of variant call format (VCF) files, which are commonly used to store genetic variation information. Annovar processes the variants and provides comprehensive annotations to aid in the interpretation of the genetic data. Annovar's annotations include details on the functional implications of the variants, their genomic positions, and any potential associations they may have with well-known genes or genetic traits.
  ANNOVAR provides a pre-built database package called "humandb" that contains the necessary files for annotation. the humandb package includes various databases, such as RefSeq, dbSNP, 1000 Genomes Project, and more.
  
  ANNOVAR is a versatile tool for variant annotation and analysis, whereas Haplotype Caller is a dedicated variant calling tool released by the Broad Institute's Genome Analysis Toolkit (GATK). ANNOVAR and Haplotype Caller can be combined in a pipeline for variant analysis even though they have different functions. 
  
### 2. Description of Interfaces and Dependencies

- Specifications of Input Files

In the Annovar module, there are specific input files that are required to perform variant annotation. The main input files used by Annovar are :

1. Variant Call Format (VCF) file:  is the primary input file for Annovar , can be generated from various sequencing technologies, such as whole-genome sequencing (WGS), whole-exome sequencing (WES) , and  contains genetic variant information, including chromosome, position, reference allele, alternate allele, genotype, quality scores, and additional annotations.
```
    input:
        vcf = "haplotype_caller_filtered/{sample}_germline_variants_filtered.vcf.gz"
```
2. Reference genome file:  typically in FASTA format and is required to accurately map the variants to their genomic coordinates
  ANNOVAR can be used with different reference genome assemblies, including hg19 (GRCh37) , it can be obtained from the ANNOVAR website
```
for human : "ref": "hg19"
for mouse : "ref": "mm9"
```
4. Annotation database files: Annovar utilizes annotation databases to provide functional annotations for the variants , usually these databases include information on gene transcripts, variant classifications, conservation scores, population frequencies, and pathogenicity predictions. 


- Ouput Files

1. Annotation output file: contains the annotated variants with additional information, including gene-based annotations, functional consequences, conservation scores, pathogenicity predictions, and population frequencies.
  Avinput file contains genetic variant information. It serves as input to ANNOVAR for the annotation process , It is typically generated from variant call format (VCF) files allowing ANNOVAR to process and annotate the genetic variants in a standardized manner
```
   output: "annovar/{sample}.avinput"
```
2. Summary statistics file (optional): this file gives summary statistics and counts for the annotated variants.It contains details on the total number of variants, the number of variants classified according to several categories (such as missense, frameshift, and synonymous), and the distribution of variants across functional regions of the genome.

3. Filtered variant output file: Annovar can generate an additional output file containing the variants that pass the specified filters ,  If filtering criteria were applied during the analysis using a filter file.
 a file containing filtered variant output with additional functional annotations provided by ANNOVAR , only the variants that meet the specified criteria and can help in focusing on specific subsets of variants for downstream analysis
```
txt     = "annovar/{sample}.%s_multianno.txt"%config["annovar"][config["samples"]]["ref"]
```
4. VCF annotation output file: VCF file that includes the original variant information from the input VCF file along with the additional annotations. This file maintains the VCF format and can be useful for compatibility with downstream tools or for further analysis.
```
vcf     = "annovar/{sample}.%s_multianno.vcf"%config["annovar"][config["samples"]]["ref"],
```

- Genome Reference

- Packages and Versions

ANNOVAR version goes back to 2020/06/08.
in order to use ANNOVAR, we need to have certain packages and dependencies installed. Here are the main requirements:

1. Perl: ANNOVAR is implemented in Perl, so you need to have Perl installed on your system. Most Unix/Linux systems come with Perl pre-installed. You can check the Perl version by running the command perl -v in the terminal.
2. BioPerl: ANNOVAR relies on BioPerl, a collection of Perl modules for bioinformatics tasks. BioPerl provides various functionalities for working with biological data, including parsing and manipulating sequence data. You can install BioPerl using the Perl package manager, cpan, by running the command cpan BioPerl.
3. Annotation databases: ANNOVAR uses annotation databases to provide functional annotations for the variants. These databases need to be downloaded and installed before running ANNOVAR. ANNOVAR comes with built-in annotation databases, such as RefSeq, dbSNP, 1000 Genomes Project, ExAC, and others. You can obtain these databases from the ANNOVAR website (https://annovar.openbioinformatics.org/en/latest/user-guide/download/) and follow the instructions provided to install them.


### 3. Issues and TODO
