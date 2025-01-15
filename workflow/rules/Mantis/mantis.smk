rule mantis_msi_TvN:
    input:
        tbam = "bam/{tsample}.nodup.recal.bam",
        tbai = "bam/{tsample}.nodup.recal.bam.bai",
        nbam = "bam/{nsample}.nodup.recal.bam",
        nbai = "bam/{nsample}.nodup.recal.bam.bai",
    output:
        msi  = "msi/{tsample}_vs_{nsample}.tsv",
        kmer_counts = "msi/{tsample}_vs_{nsample}.kmer_counts.tsv",
        kmer_counts_filtered="msi/{tsample}_vs_{nsample}.kmer_counts_filtered.tsv",
    log: "logs/somatic_msi_mantis/{tsample}_vs_{nsample}.log",
    params:
        queue = 'shortq',
        mantis = config["mantis"]["script"],
        ref = config["bwa"][config["samples"]]["index"],
        ms  = config["mantis"][config["samples"]]["bed"], 
        mrq = 20,
        mlq = 25,
        mlc = 20,
        mrr = 1
    threads: 4
    conda: 'mantis'
    resources:
        queue="shortq",
        mem_mb=16000,
        time_min=30
    shell:
        """
        python {params.mantis} \
            --genome {params.ref} \
            --bedfile {params.ms} \
            --tumor {input.tbam} \
            --normal {input.nbam} \
            -mrq {params.mrq} \
            -mlq {params.mlq} \
            -mlc {params.mlc} \
            -mrr {params.mrr} \
            --threads {threads} \
            --output {output.msi} &> {log}
        """
