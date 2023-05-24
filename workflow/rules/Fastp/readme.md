### 1. Description of Fastp Module

### 2. Description of Interfaces and Dependencies

- Specifications of Input Files

- Ouput Files

- Genome Reference

- Packages and Versions

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
