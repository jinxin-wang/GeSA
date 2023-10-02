## A rule to estimate cross-sample contamination using GetPileupSummaries and CalculateContamination, step one GetPileupSummaries
rule get_pileup_summaries:
    input:
        tumor_bam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",
    output:
        temp("cross_sample_contamination/{tsample}_getpileupsummaries.table")
    params:
        queue = "shortq",
        gatk  = config["gatk"]["app"],
        mutect_filter_ref = config["gatk"][config["samples"]]["mutect_filter_ref"],
    log:
        "logs/cross_sample_contamination/{tsample}_getpileupsummaries.table.log"
    threads : 4
    resources:
        mem_mb = 51200
    shell:
        "{params.gatk} --java-options \"-Xmx48g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" GetPileupSummaries"
        " -I {input.tumor_bam}"
        " -L {params.mutect_filter_ref}"
        " -V {params.mutect_filter_ref}"
        " -O {output} 2> {log}"
        
##  A rule to estimate cross-sample contamination using GetPileupSummaries and CalculateContamination, step two CalculateContamination
rule calculate_contamination:
    input:
        table = "cross_sample_contamination/{tsample}_getpileupsummaries.table",
    output:
        temp("cross_sample_contamination/{tsample}_calculatecontamination.table")
    params:
        queue = "shortq",
        gatk  = config["gatk"]["app"]
    log:
        "logs/cross_sample_contamination/{tsample}_calculatecontamination.table.log"
    threads : 4
    resources:
        mem_mb = 40960
    shell:
        "{params.gatk} --java-options \"-Xmx40g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" CalculateContamination"
        " -I {input.table}"
        " -O {output} 2> {log}"

