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
