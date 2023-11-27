## A rule to get mapping stats, with GATK CollectHsMetrics
rule collect_Hs_metrics:
    input:
        bam = "bam/{sample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam",
        bai = "bam/{sample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam.bai",
    output:
        "mapping_QC/HsMetrics/{sample}_HsMetrics.tsv"
    params:
        queue    = "shortq",
        # gatk     = config["gatk"]["app"],
        gatk = config["gatk"][config["samples"]]["app"],
        bait     = config["gatk"][config["samples"]][config["seq_type"]]["hsmetrics_bait"],
        interval = config["gatk"][config["samples"]][config["seq_type"]]["hsmetrics_interval"],
    log:
        "logs/mapping_QC/{sample}_HsMetrics.log"
    threads : 4
    resources:
        mem_mb = 10240
    shell:
        "{params.gatk} --java-options \"-Xmx8g  -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" CollectHsMetrics"
        " -TI {params.interval}"
        " -BI {params.bait}"
        " -I {input.bam}"
        " -O {output} 2> {log}"
