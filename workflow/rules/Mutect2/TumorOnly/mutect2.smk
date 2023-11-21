## A rule to call somatic SNPs and indels via local re-assembly of haplotypes, on tumor sample only, with GATK Mutect2
## Use list of target from target_interval_list.bed if it is present in the working directory

## [J. WANG] add " --native-pair-hmm-threads {threads} " to shell
##           raise threads 1 to 24
##           raise mem_mb to 51200

rule Mutect2_tumor_only:
    input:
        tumor_bam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",
    output:
        VCF   = temp("Mutect2_T_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.gz"),
        INDEX = temp("Mutect2_T_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.gz.tbi"),
        STATS = temp("Mutect2_T_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.gz.stats"),
    params:
        queue = "shortq",
        gatk        = config["gatk"]["app"],
        samtools    = config["samtools"]["app"],
        index       = config["gatk"][config["samples"]]["genome_fasta"],
        interval    = config["gatk"][config["samples"]][config["seq_type"]]["mutect_interval_dir"] + "/{interval}.bed",
        gnomad_ref  = config["gatk"][config["samples"]]["gnomad_ref"]
    log:
        "logs/Mutect2_T_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.log"
    threads : 8
    resources:
        mem_mb = 10240
    shell:
        "read readGroup_{wildcards.tsample} < <({params.samtools} view -H {input.tumor_bam}| grep \'^@RG\' | awk -F\'SM:\' \'{{split($2,a,\" \"); print a[1]}}\' -);"
        "{params.gatk} --java-options \"-Xmx10g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" Mutect2"
        " --native-pair-hmm-threads {threads} "
        " --dont-use-soft-clipped-bases true"
        " -L {params.interval}"
        " --reference {params.index} "
        " --germline-resource {params.gnomad_ref}"
        " -I {input.tumor_bam}"
        " -tumor $readGroup_{wildcards.tsample}"
        " -O {output.VCF} 2> {log}" 
        
rule concatenate_mutect2_tumor_only:
    input:
        vcfs = expand("Mutect2_T_tmp/{{tsample}}_tumor_only_T_ON_{mutect_interval}.vcf.gz", mutect_interval=mutect_intervals)
    output:
        concatened_vcf = temp("Mutect2_T/{tsample}_tumor_only_T.vcf.gz"),
        vcf_liste      = temp("mutect2_T_tmp_list/{tsample}_tumor_only_T_mutect2_tmp.list"),
    params:
        queue = "shortq",
        gatk = config["gatk"]["app"]
    threads : 1
    resources:
        mem_mb = 10240
    log:
        "logs/vcftools/{tsample}_tumor_only_T.vcf.log"
    shell :
        "ls -1a Mutect2_T_tmp/{wildcards.tsample}_tumor_only_T_ON_*gz > mutect2_T_tmp_list/{wildcards.tsample}_tumor_only_T_mutect2_tmp.list &&"
        "{params.gatk}  --java-options \"-Xmx10g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" MergeVcfs -I {output.vcf_liste} -O {output.concatened_vcf} 2> {log}"

rule concatenate_mutect2_tumor_only_stats:
    input:
        vcfs = expand("Mutect2_T_tmp/{{tsample}}_tumor_only_T_ON_{mutect_interval}.vcf.gz.stats", mutect_interval=mutect_intervals)
    output:
        concatened_stats = temp("Mutect2_T/{tsample}_tumor_only_T.vcf.gz.stats"),
        stat_liste       = temp("mutect2_T_tmp_list/{tsample}_tumor_only_T_mutect2_tmp_stats.list"),
    params:
        queue = "shortq",
        gatk = config["gatk"]["app"]
    threads : 4
    resources:
        mem_mb = 10240
    log:
        "logs/vcftools/{tsample}_tumor_only_T.vcf.log"
    shell :
        "ls -1a Mutect2_T_tmp/{wildcards.tsample}_tumor_only_T_ON_*stats > mutect2_T_tmp_list/{wildcards.tsample}_tumor_only_T_mutect2_tmp_stats.list &&"
        "{params.gatk}  --java-options \"-Xmx10g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" MergeMutectStats --stats {output.stat_liste} -O {output.concatened_stats} 2> {log}"

## include: "../Common/collectSeqAM.smk"
## include: "../Common/estiContamination.smk"

## A rule to filter variant call, from mutect tumor only
rule filter_mutect_calls_tumor_only:
    input :
        Mutect2_vcf = "Mutect2_T/{tsample}_tumor_only_T.vcf.gz",
        Mutect2_stats = "Mutect2_T/{tsample}_tumor_only_T.vcf.gz.stats",
        contamination_table = "cross_sample_contamination/{tsample}_calculatecontamination.table",
    output:
        VCF   = temp("Mutect2_T/{tsample}_tumor_only_filtered_T.vcf.gz"),
        INDEX = temp("Mutect2_T/{tsample}_tumor_only_filtered_T.vcf.gz.tbi"),
    params:
        queue = "mediumq",
        # gatk = "/mnt/beegfs/software/gatk/4.1.4.1/gatk",
        gatk  = config["gatk"]["app"],
        index = config["gatk"][config["samples"]]["genome_fasta"],
    log:
        "logs/filter_Mutect2_T/{tsample}_tumor_only_filtered_T.vcf.gz.log"
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        "{params.gatk} --java-options \"-Xmx10g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" FilterMutectCalls"
        " -V {input.Mutect2_vcf}"
        " -R {params.index}"
        " --contamination-table {input.contamination_table}"
        " -O {output.VCF} 2> {log}"
        
## A rule to filter VCF on orientation bias, for OxoG and FFPE, from mutect tumor only 
rule Filter_By_Orientation_Bias_tumor_only:
    input :
        Mutect2_vcf = "Mutect2_T/{tsample}_tumor_only_filtered_T.vcf.gz",
        Mutect2_idx = "Mutect2_T/{tsample}_tumor_only_filtered_T.vcf.gz.tbi",
        pre_adapter_detail_metrics = "collect_Sequencing_Artifact_Metrics/{tsample}_artifact.pre_adapter_detail_metrics.txt"
    output:
        filtered_vcf       = "Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz",
        filtered_vcf_index = "Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz.tbi",
    params:
        queue = "mediumq",
        # gatk = "/mnt/beegfs/software/gatk/4.1.4.1/gatk",
        gatk  = config["gatk"]["app"],
    log:
        "logs/filter_Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz.log"
    threads : 4
    resources:
        mem_mb = 10240
    shell:
        "{params.gatk} --java-options \"-Xmx10g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" FilterByOrientationBias"
        " -V {input.Mutect2_vcf}"
        " -AM G/T -AM C/T"
        " -P {input.pre_adapter_detail_metrics}"
        " -O {output.filtered_vcf} 2> {log}"     
