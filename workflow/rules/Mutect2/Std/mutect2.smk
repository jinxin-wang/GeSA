## A rule to call somatic SNPs and indels via local re-assembly of haplotypes, on tumor versus normal tissu, with GATK Mutect2
## Use list of target from target_interval_list.bed if it is present in the working directory
rule Mutect2:
    input:
        tumor_bam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        norm_bam = "bam/{nsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{nsample}.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",
        norm_bai = "bam/{nsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{nsample}.recal.bam.bai",
    output:
        VCF   = temp("Mutect2_TvN_tmp/{tsample}_Vs_{nsample}_TvN_ON_{interval}.vcf.gz"),
        INDEX = temp("Mutect2_TvN_tmp/{tsample}_Vs_{nsample}_TvN_ON_{interval}.vcf.gz.tbi"),
        STATS = temp("Mutect2_TvN_tmp/{tsample}_Vs_{nsample}_TvN_ON_{interval}.vcf.gz.stats"),
    params:
        queue = "shortq",
        tumor_group = "{tsample}",
        norm_group  = "{nsample}",
        gatk        = config["gatk"]["app"],
        samtools    = config["samtools"]["app"],
        gnomad_ref  = config["gatk"][config["samples"]]["gnomad_ref"],
        index       = config["gatk"][config["samples"]]["genome_fasta"],
        interval    = config["gatk"][config["samples"]][config["seq_type"]]["mutect_interval_dir"] + "/{interval}.bed",
    log:
        "logs/Mutect2_TvN/{tsample}_Vs_{nsample}_TvN_ON_{interval}.vcf.log"
    threads : 8
    resources:
        mem_mb = 25600
    shell: 
        "read readGroup_{wildcards.tsample} < <({params.samtools} view -H {input.tumor_bam} | grep \'^@RG\' | awk -F\'SM:\' \'{{split($2,a,\" \"); print a[1]}}\' -);"
        "read readGroup_{wildcards.nsample} < <({params.samtools} view -H {input.norm_bam}  | grep \'^@RG\' | awk -F\'SM:\' \'{{split($2,a,\" \"); print a[1]}}\' -);"
        "{params.gatk} --java-options \"-Xmx20g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" Mutect2"
        " --dont-use-soft-clipped-bases true "
        " --native-pair-hmm-threads {threads} "
        " -L {params.interval}"
        " --reference {params.index} "
        " --germline-resource {params.gnomad_ref}"
        " -I {input.tumor_bam}"
        " -I {input.norm_bam}"
        " -tumor $readGroup_{wildcards.tsample}"
        " -normal $readGroup_{wildcards.nsample}"
        " -O {output.VCF} 2> {log}"

## Concatenate mutect2 results
rule concatenate_mutect2:
    input:
        vcfs = expand("Mutect2_TvN_tmp/{{tsample}}_Vs_{{nsample}}_TvN_ON_{mutect_interval}.vcf.gz", mutect_interval=mutect_intervals)
    output:
        concatened_vcf = temp("Mutect2_TvN/{tsample}_Vs_{nsample}_TvN.vcf.gz"),
        vcf_liste      = temp("Mutect2_TvN_tmp_list/{tsample}_Vs_{nsample}_TvN_mutect2_tmp.list"),
    params:
        queue = "shortq",
        gatk = config["gatk"]["app"]
    threads : 4
    resources:
        mem_mb = 10240
    log:
        "logs/vcftools/{tsample}_Vs_{nsample}_TvN.vcf.log"
    shell :
        "ls -1a Mutect2_TvN_tmp/{wildcards.tsample}_Vs_{wildcards.nsample}_TvN_ON_*gz > Mutect2_TvN_tmp_list/{wildcards.tsample}_Vs_{wildcards.nsample}_TvN_mutect2_tmp.list && "
        "{params.gatk}  --java-options \"-Xmx8g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" MergeVcfs -I {output.vcf_liste} -O {output.concatened_vcf} 2> {log}"
 
## Concatenation of Mutect2 stats
rule concatenate_mutect2_stats:
    input:
        vcfs = expand("Mutect2_TvN_tmp/{{tsample}}_Vs_{{nsample}}_TvN_ON_{mutect_interval}.vcf.gz.stats", mutect_interval=mutect_intervals)
    output:
        concatened_stats = temp("Mutect2_TvN/{tsample}_Vs_{nsample}_TvN.vcf.gz.stats"),
        stat_liste       = temp("Mutect2_TvN_tmp_list/{tsample}_Vs_{nsample}_TvN_mutect2_tmp_stats.list"),
    params:
        queue = "shortq",
        gatk = config["gatk"]["app"]
    threads : 4
    resources:
        mem_mb = 10240
    log:
        "logs/vcftools/{tsample}_Vs_{nsample}_TvN.vcf.log"
    shell :
        "ls -1a Mutect2_TvN_tmp/{wildcards.tsample}_Vs_{wildcards.nsample}_TvN_ON_*stats > Mutect2_TvN_tmp_list/{wildcards.tsample}_Vs_{wildcards.nsample}_TvN_mutect2_tmp_stats.list &&"
        "{params.gatk}  --java-options \"-Xmx8g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" MergeMutectStats --stats {output.stat_liste} -O {output.concatened_stats} 2> {log}"

## include: "../Common/collectSeqAM.smk"
## include: "../Common/estiContamination.smk"

## A rule to filter variant call, from mutect tumor Vs normal
rule filter_mutect_calls:
    input :
        Mutect2_vcf = "Mutect2_TvN/{tsample}_Vs_{nsample}_TvN.vcf.gz",
        Mutect2_stats = "Mutect2_TvN/{tsample}_Vs_{nsample}_TvN.vcf.gz.stats",
        contamination_table = "cross_sample_contamination/{tsample}_calculatecontamination.table",
    output:
        VCF   = temp("Mutect2_TvN/{tsample}_Vs_{nsample}_filtered_TvN.vcf.gz"),
        INDEX = temp("Mutect2_TvN/{tsample}_Vs_{nsample}_filtered_TvN.vcf.gz.tbi"),
    params:
        queue = "shortq",
        # gatk = "/mnt/beegfs/software/gatk/4.1.4.1/gatk",
        gatk  = config["gatk"]["app"],
        index = config["gatk"][config["samples"]]["genome_fasta"],
    log:
        "logs/filter_Mutect2_TvN/{tsample}_Vs_{nsample}_filtered_TvN.vcf.gz.log"
    threads : 4
    resources:
        mem_mb = 25600
    shell:
        "{params.gatk} --java-options \"-Xmx20g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" FilterMutectCalls "
        " -V {input.Mutect2_vcf} "
        " -R {params.index} "
        " --contamination-table {input.contamination_table} "
        " -O {output.VCF} 2> {log} "

## A rule to filter VCF on orientation bias, for OxoG and FFPE, from mutect tumor Vs normal 
rule Filter_By_Orientation_Bias:
    input :
        Mutect2_vcf = "Mutect2_TvN/{tsample}_Vs_{nsample}_filtered_TvN.vcf.gz",
        Mutect2_idx = "Mutect2_TvN/{tsample}_Vs_{nsample}_filtered_TvN.vcf.gz.tbi",
        pre_adapter_detail_metrics = "collect_Sequencing_Artifact_Metrics/{tsample}_artifact.pre_adapter_detail_metrics.txt"
    output:
        filtered_vcf       = "Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz",
        filtered_vcf_index = "Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz.tbi",
    params:
        queue = "shortq",
        # gatk = "/mnt/beegfs/software/gatk/4.1.4.1/gatk",
        gatk  = config["gatk"]["app"],
    log:
        "logs/filter_Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz.log"
    threads : 4
    resources:
        mem_mb = 25600
    shell:
        "{params.gatk} --java-options \"-Xmx20g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" FilterByOrientationBias"
        " -V {input.Mutect2_vcf}"
        " -AM G/T -AM C/T"
        " -P {input.pre_adapter_detail_metrics}"
        " -O {output.filtered_vcf} 2> {log}"
