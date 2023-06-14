## A rule to collect sequencing artifact metrics

--> rule Collect_Sequencing_Artifact_Metrics:
The rule "Collect_Sequencing_Artifact_Metrics" is a hypothetical rule that could be part of a bioinformatics pipeline or workflow for analyzing DNA 
sequencing data. This rule is likely used to collect various metrics related to sequencing artifacts, which are errors or biases that can occur during 
the sequencing process.
The purpose of this rule is to assess the quality and reliability of the sequencing data by quantifying the presence and characteristics of sequencing 
artifacts. These artifacts can arise from various sources, such as PCR amplification biases, sequencing machine errors, or sample preparation issues.

- input files :
tumor_bam: This variable represents the path to the tumor sample's BAM (Binary Alignment Map) file, which contains the aligned sequencing data for the 
tumor sample. The BAM file is specified using a string format with {tsample} representing the tumor sample name.
```
tumor_bam: This variable represents the path to the tumor sample's BAM (Binary Alignment Map) file, which contains the aligned sequencing data for the tumor sample. The BAM file is specified using a string format with {tsample} representing the tumor sample name.
```
- output files :
temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.bait_bias_detail_metrics.txt"): 
This file contains the detailed metrics related to bait bias. Bait bias refers to biases in capturing specific genomic regions during 
the target enrichment step of the sequencing process.

temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.bait_bias_summary_metrics.txt"): 
This file contains summarized metrics for bait bias. It provides an overview of the biases observed in capturing the genomic regions
targeted by the baits.

temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.error_summary_metrics.txt"):
This file contains summary metrics related to sequencing errors. It provides information on the overall error rates, 
such as base substitution, insertion, and deletion rates.

temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.pre_adapter_detail_metrics.txt"): 
This file contains detailed metrics related to pre-adapter artifacts. Pre-adapter artifacts refer to biases or errors that can occur during 
library preparation before the sequencing process, such as PCR amplification artifacts.

temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.pre_adapter_summary_metrics.txt"): 
This file contains summarized metrics for pre-adapter artifacts. It provides an overview of the biases or errors observed during library preparation.
```
        temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.bait_bias_detail_metrics.txt"),
        temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.bait_bias_summary_metrics.txt"),
        temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.error_summary_metrics.txt"),
        temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.pre_adapter_detail_metrics.txt"),
        temp("collect_Sequencing_Artifact_Metrics/{tsample}_artifact.pre_adapter_summary_metrics.txt")
```


## A rule to estimate cross-sample contamination using GetPileupSummaries and CalculateContamination, step one GetPileupSummaries
--> rule get_pileup_summaries:
The rule "get_pileup_summaries" is a step within a larger rule that aims to estimate cross-sample contamination using the GetPileupSummaries and 
CalculateContamination tools. In this context, the "get_pileup_summaries" step focuses on generating pileup summaries for the input samples 
to facilitate the subsequent estimation of contamination levels.

The "get_pileup_summaries" step is crucial in preparing the necessary data for contamination estimation. By generating pileup summaries for each sample, 
it allows for the analysis of coverage and base composition at specific genomic positions. These summaries provide valuable information for subsequent 
steps, such as identifying potential contamination events and estimating contamination levels among the samples.

- input files : 
tumor_bam: This variable represents the path to the tumor sample's BAM (Binary Alignment Map) file, which contains the aligned sequencing data for the tumor sample. The BAM file path is specified using a string format with {tsample} representing the tumor sample name.

tumor_bai: This variable represents the path to the tumor sample's corresponding BAI (BAM index) file. The BAI file is used to facilitate efficient access and querying of the BAM file.

```
        tumor_bam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",
```

- output files : 
This file represents the pileup summaries for the tumor sample, specifically in a table format. The pileup summaries contain information such as read depth, base composition, and mapping quality at specific genomic positions.

```
        temp("cross_sample_contamination/{tsample}_getpileupsummaries.table")
```

##  A rule to estimate cross-sample contamination using GetPileupSummaries and CalculateContamination, step two CalculateContamination

--> rule calculate_contamination:

The "calculate_contamination" step utilizes the pileup summary information from the "get_pileup_summaries" step and applies statistical methods to estimate the level of cross-sample contamination between the tumor and normal samples. By comparing relevant features, such as allele frequencies, it can provide insights into potential contamination events that may affect the accuracy and interpretation of downstream analyses.

- input files : 

table: This variable represents the path to the pileup summary table file for a specific sample. The pileup summary table contains relevant information such as read depth, base composition, and mapping quality at specific genomic positions.
```
        table = "cross_sample_contamination/{tsample}_getpileupsummaries.table"
```

- output files : 
This file represents the contamination estimation table for a specific sample. 
The contamination estimation table contains the results of the contamination analysis, including the estimated contamination level, confidence intervals, and any additional relevant metrics or statistics. The table format allows for structured representation and easy interpretation of the contamination estimation results.

```
        temp("cross_sample_contamination/{tsample}_calculatecontamination.table")
```

