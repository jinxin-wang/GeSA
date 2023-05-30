### 1. Description of Fastp Module

Fastp is an ultra-fast FASTQ preprocessor with useful quality control and data-filtering features. It is developed in C++ with multithreading supported to afford high performance. It can perform quality control, adapter trimming, quality filtering, per-read quality pruning and many other operations with a single scan of the FASTQ data. Quality control and reporting are displayed both before and after filtering, allowing for a clear depiction of the consequences of the filtering process , it helps enhance the accuracy and realibility of downstream analysis such as variant calling , genome assembly and transcriptome analysis.


### 2. Description of Interfaces and Dependencies

- Specifications of Input Files

first of all , we need to specify the input file for either single-end or paired-end data 
for single-end data :
```
input:
            fastq_0="DNA_samples/{sample}_0.fastq.gz",
```
for paired-end data 
```
            fastq_1="DNA_samples/{sample}_1.fastq.gz",
            fastq_2="DNA_samples/{sample}_2.fastq.gz",
```

- Ouput Files

the fastp module generate several output files that provides information about the preprocessing steps and the resulting processed data 
1. processed FASTQ file :
For single-end data :
```
            fastq_clean = temp('DNA_samples_clean/{sample}_0.fastq.gz')
```
For paired-end data :
```
            fastq_clean_1 = temp('DNA_samples_clean/{sample}_1.fastq.gz'),
            fastq_clean_2 = temp('DNA_samples_clean/{sample}_2.fastq.gz')
```
2. HTML report : fastp generate an HTML report file that contains the detailed statistics and visualization data about the quality control and processing steps , in order to help the users asses the quality of the input data and evalute the effect of the preprocessing steps , it usually includes graphs showing the distribution of read qualities , adapter content , read length 

```           
            html_report = 'fastp_reports/{sample}_fastp_report.html'
```
3. JSON report : which is a report that contains summary statistics and detailed informations about each processed read . it is usually used to extract specific information for downstream analysis 
```
json_report = 'fastp_reports/{sample}_fastp_report.json'
```
- Genome Reference

fastp does not require a specific genome reference , we only need to specify the raw sequencing data in FASTQ format as an input within the Fastp module

- Packages and Versions.

### 3. Issues and TODO


#### [fastp](https://github.com/OpenGene/fastp#readme): A tool designed to provide fast all-in-one preprocessing for FastQ files. 
currently used version 0.20.1

[paper](https://academic.oup.com/bioinformatics/article/34/17/i884/5093234)

### Review of the used options in the rules

- **-i, --in1; -I, --in2** # read1 and read2 input file name

- **-o, --out1; -O, --out2** # read1 and read2 output file name

- **-j, --json** # the json format report file name (default string [=fastp.json])

- **-h, --html** # the html format report file name (default string [=fastp.html])

- **-w, --thread** # worker thread number, default is 2

- **--dont_overwrite** # don't overwrite existing files.

- **-z, --compression 9** # compression level for gzip output (1 ~ 9). 1 is fastest, 9 is smallest, default is 4. 

overlap-analysis-based trim method, **two assumptions**:
1. the first is that only one adapter exists in the data
2. the second is that adapter sequences exist only in the read tails. 

**remark**: For SE data, if an adapter sequence is given, then automatic adapter-sequence detection will be disabled. For PE data, the adapter sequence will be used for sequence-matching-based adapter trimming only when fastp fails to detect a good overlap in the pair.

PolyG is a common issue observed in Illumina NextSeq and NovaSeq series, which are based on two-color chemistry. Such systems use two different lights (i.e. red and green) to represent four bases: a base with only a detected red-light signal is called C; a base with only a detected green light signal is called T; a base with both red and green light detected is called A; and a base with no light detected is called G. However, as the sequencing by synthesis proceeds to subsequent cycles, the signal strength of each DNA cluster becomes progressively weaker. This issue causes some T and C to be wrongly interpreted as G in the read tails, a problem otherwise known as a polyG tail.

- **--trim_poly_g** # force polyG tail trimming, by default trimming is automatically enabled for Illumina NextSeq/NovaSeq data

- **--trim_poly_x** # enable polyX trimming in 3' ends.

- **-l, --length_required 25** # reads shorter than length_required will be discarded, default is 15.

Some sequences, or even entire reads, can be overrepresented in FASTQ data. Analysis of these overrepresented sequences provides an overview of certain sequencing artifacts such as PCR over-duplication, polyG tails and adapter contamination. 

- **-p, --overrepresentation_analysis** # enable overrepresented sequence analysis

- **--adapter_fasta** # specify a FASTA file to trim both read1 and read2 (if PE) by all the sequences in this FASTA file
```
$ cat /mnt/beegfs/userdata/i_padioleau/genome_data/adapters_for_fastp.tsv

>BGI_adapter3
AAGTCGGAGGCCAAGCGGTCTTAGGAAGACAA
>BGI_adapter5
AAGTCGGATCGTAGCCATGTCGTTCTGTGAGCCAAGGAGTTG

>Illumina_Universal_Adapter
AGATCGGAAGAG
>Illumina_Small_RNA_3_Adapter
TGGAATTCTCGG
>Illumina_Small_RNA_5_Adapter
GATCGTCGGACT

>Nextera_Transposase_Sequence
CTGTCTCTTATA
>Nextera_ampliseq
CTGTCTCTTATACACATCT

>Nextera2
ATGTGTATAAGAGACA
>Nextera3
AGATGTGTATAAGAGACAG

>TruSeq_1
AGATCGGAAGAGCACACGTCTGAACTCCAGTCA
>TruSeq_2
AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT

>TruSeq_universal_adaper
AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT
>TruSeq_methylation_1
AGATCGGAAGAGCACACGTCTGAAC
>TruSeq_methylation_2
AGATCGGAAGAGCGTCGTGTAGGGA

>TruSeq_ribo
AGATCGGAAGAGCACACGTCT

>TruSeq_small_rna
TGGAATTCTCGGGTGCCAAGG
>SOLID_Small_RNA_Adapter
CGCCTTGGCCGT
```
