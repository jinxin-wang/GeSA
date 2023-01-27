## A rule to collect sequencing artifact metrics
rule Collect_Sequencing_Artifact_Metrics:
    input :
        tumor_bam = "bam/{tsample}.nodup.recal.bam" if config["REMOVE_DUPLICATES"]=="True" else "bam/{tsample}.recal.bam",
        index = config["GENOME_FASTA"]
    output:
        "collect_Sequencing_Artifact_Metrics/{tsample}_artifact.bait_bias_detail_metrics.txt",
        "collect_Sequencing_Artifact_Metrics/{tsample}_artifact.bait_bias_summary_metrics.txt",
        "collect_Sequencing_Artifact_Metrics/{tsample}_artifact.error_summary_metrics.txt",
        "collect_Sequencing_Artifact_Metrics/{tsample}_artifact.pre_adapter_detail_metrics.txt",
        "collect_Sequencing_Artifact_Metrics/{tsample}_artifact.pre_adapter_summary_metrics.txt"      
    params:
        queue = "mediumq",
        output_prefix = "collect_Sequencing_Artifact_Metrics/{tsample}_artifact",
        gatk = config["APP_GATK"]
    log:
        "logs/filter_Mutect2/{tsample}_artifact.log"
    threads : 1
    resources:
        mem_mb = 40000
    shell:
        "{params.gatk} --java-options \"-Xmx40g  -Djava.io.tmpdir=/mnt/beegfs/scratch/tmp \" CollectSequencingArtifactMetrics"
        " -I {input.tumor_bam}"
        " --FILE_EXTENSION \".txt\""
        " -R {input.index}"
        " -O {params.output_prefix} 2> {log}"

