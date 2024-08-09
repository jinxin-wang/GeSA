## A rule to do Base Quality Score Recalibration (BQSR) - second pass, GATK BaseRecalibrator
rule base_recalibrator_pass2:
    input:
        bam = "bam/{sample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam",
        bai = "bam/{sample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam.bai",
    output:
        "BQSR/{sample}_BQSR_pass2.table"
    params:
        queue = lambda w,input: "shortq" if os.path.getsize(input.bam)/1024/1024/1024 < 50 else 'mediumq',
        # gatk  = config["gatk"]["app"],
        gatk = config["gatk"][config["samples"]]["app"],
        target_interval = config["gatk"][config["samples"]]["target_interval"],
        index           = config["gatk"][config["samples"]]["genome_fasta"],
        gnomad_ref      = config["gatk"][config["samples"]]["gnomad_ref"],
    log:
        "logs/BQSR/{sample}_BQSR_pass2.log"
    threads: 1
    resources:
        mem_mb = 51200
    shell:
        "{params.gatk} --java-options \"-Xmx40g -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp -XX:+UseParallelGC -XX:ParallelGCThreads={threads} \" BaseRecalibrator "
        " -R {params.index}"
        " {params.target_interval}"
        " --known-sites {params.gnomad_ref}"
        " -I {input.bam}"
        " -O {output} 2> {log}"

## A rule to analyse covariate BQSR - GATK AnalyzeCovariates
rule analyze_covariates_bqsr:
    input:
        table1 = "BQSR/{sample}_BQSR_pass1.table",
        table2 = "BQSR/{sample}_BQSR_pass2.table"
    output:
        "BQSR/{sample}_BQSR_report.pdf"
    params:
        queue = "shortq",
        # gatk = config["gatk"]["app"],
        gatk = config["gatk"][config["samples"]]["app"],
    log:
        "logs/BQSR/{sample}_AnalyzeCovariates.log"
    threads : 1
    resources:
        mem_mb = 51200
    shell:
        "module load r/4.1.1 && "
        "{params.gatk} --java-options \"-Xmx40g -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp -XX:+UseParallelGC -XX:ParallelGCThreads={threads} \" AnalyzeCovariates"
        " --before-report-file {input.table1}"
        " --after-report-file {input.table2}"
        " --plots-report-file {output} 2> {log}"

