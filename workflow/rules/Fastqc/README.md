### 1. Description of Fastqc Module
FastQC provides a simple way to do some quality checks on raw sequence data coming from high throughput sequencing pipelines. It provides a modular set of analyses, which you can use to obtain an impression of whether your data has any problems that you should be aware of before moving on to the next analysis.
FastQC does the following:
- accepts FASTQ files (or BAM files) as input
- generates summary graphs and tables to help assess your data
- generates an easy-to-view HTML-based report with the graphs and tables

### 2. Description of Interfaces and Dependencies

- Specifications of Input Files

input files for the FastQC module is typically one or more FASTQ files . FASTQ file contains the high-throughtput sequencing data, and they contain the DNA sequence reads and their corresponding quality scores
in order to run FastQC , we need firstly to specify the input FASTQ file 
```
fastq='DNA_samples/{sample}.fastq.gz'
```
- Ouput Files
1. HTML report : an interactive HTML report is generated to provide a summary of the quality control analysis . It usually contains visualizations , quality metrics and summary statistics for various metrics evaluated by FastQC 
```
'fastq_QC_raw/{sample}_fastqc.html'
```
2. ZIP file :a ZIP archive containing individual result files and data generated during the analysis is created , it includes images , data tables and other files associated with the analysis
```
'fastq_QC_raw/{sample}_fastqc.zip'
```

The FastQC module can also be used to analyze cleaned or processed FASTQ files as input and in order to use the FastQC module with cleaned FastQ file as the input , we follow the same steps .

- Genome Reference

FastQC does not require a specific genome reference , we only need to specify the raw or processed sequencing data in FASTQ format as an input within the module

- Packages and Versions

### 3. Issues and TODO
