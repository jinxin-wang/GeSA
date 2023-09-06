## A rule to call somatic SNPs and indels via local re-assembly of haplotypes, on tumor sample only with Panel of Normal, with GATK Mutect2
## Use list of target from target_interval_list.bed if it is present in the working directory

rule Mutect2_tumor_only_pon:
    input:
        tumor_bam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",
        panel_of_normal = "PoN/{panel_of_normal}.vcf",
    output:
        VCF   = temp("Mutect2_Tp_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.gz"),
        INDEX = temp("Mutect2_Tp_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.gz.tbi"),
        STATS = temp("Mutect2_Tp_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.gz.stats"),
    params:
        queue = "shortq",
        gatk        = config["gatk"]["app"],
        index       = config["gatk"][config["samples"]]["genome_fasta"],
        interval    = config["gatk"][config["samples"]][config["seq_type"]]["mutect_interval_dir"] + "/{interval}.bed",
        gnomad_ref  = config["gatk"][config["samples"]]["gnomad_ref"],
    log:
        "logs/Mutect2_Tp_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.log"
    threads : 8
    resources:
        mem_mb = 25600
    shell:
        "read readGroup_{wildcards.tsample} < <(samtools view -H {input.tumor_bam}| grep \'^@RG\' | awk -F\'SM:\' \'{{split($2,a,\" \"); print a[1]}}\' -);"
        "{params.gatk} --java-options \"-Xmx20g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" Mutect2"
        " --dont-use-soft-clipped-bases true"
        " --native-pair-hmm-threads {threads} "
        " -L {params.interval}"
        " --reference {params.index} "
        " -pon {input.panel_of_normal}"
        " --germline-resource {params.gnomad_ref}"
        " -I {input.tumor_bam}"
        " -tumor $readGroup_{wildcards.tsample}"
        " -O {output.VCF} 2> {log}"
        
rule concatenate_mutect2_tumor_only_pon:
    input:
        vcfs = expand("Mutect2_Tp_tmp/{{tsample}}_PON_{{panel_of_normal}}_Tp_ON_{mutect_interval}.vcf.gz", mutect_interval=mutect_intervals),
        panel_of_normal = "PoN/{panel_of_normal}.vcf"
    output:
        concatened_vcf = temp("Mutect2_Tp/{tsample}_PON_{panel_of_normal}_Tp.vcf.gz"),
        vcf_liste      = temp("mutect2_Tp_tmp_list/{tsample}_PON_{panel_of_normal}_Tp_mutect2_tmp.list"),
    params:
        queue = "shortq",
        gatk = config["gatk"]["app"]
    threads : 1
    resources:
        mem_mb = 10240
    log:
        "logs/vcftools/{tsample}_PON_{panel_of_normal}_Tp.vcf.log"
    shell :
        "ls -1a Mutect2_Tp_tmp/{wildcards.tsample}_PON_{wildcards.panel_of_normal}_Tp_ON_*gz > mutect2_Tp_tmp_list/{wildcards.tsample}_PON_{wildcards.panel_of_normal}_Tp_mutect2_tmp.list &&"
        "{params.gatk}  --java-options \"-Xmx10g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" MergeVcfs -I {output.vcf_liste} -O {output.concatened_vcf} 2> {log}"

rule concatenate_mutect2_tumor_only_pon_stats:
    input:
        vcfs = expand("Mutect2_Tp_tmp/{{tsample}}_PON_{{panel_of_normal}}_Tp_ON_{mutect_interval}.vcf.gz.stats", mutect_interval=mutect_intervals),
        panel_of_normal = "PoN/{panel_of_normal}.vcf"
    output:
        concatened_stats = temp("Mutect2_Tp/{tsample}_PON_{panel_of_normal}_Tp.vcf.gz.stats"),
        stat_liste       = temp("mutect2_Tp_tmp_list/{tsample}_PON_{panel_of_normal}_Tp_mutect2_tmp_stats.list"),
    params:
        queue = "shortq",
        gatk = config["gatk"]["app"]
    threads : 4
    resources:
        mem_mb = 10240
    log:
        "logs/vcftools/{tsample}_PON_{panel_of_normal}_Tp.vcf.log"
    shell :
        "ls -1a Mutect2_Tp_tmp/{wildcards.tsample}_PON_{wildcards.panel_of_normal}_Tp_ON_*stats > mutect2_Tp_tmp_list/{wildcards.tsample}_PON_{wildcards.panel_of_normal}_Tp_mutect2_tmp_stats.list &&"
        "{params.gatk}  --java-options \"-Xmx10g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" MergeMutectStats --stats {output.stat_liste} -O {output.concatened_stats} 2> {log}"

## include: "../Common/collectSeqAM.smk"
## include: "../Common/estiContamination.smk"

## A rule to filter variant call, from mutect tumor only with PoN
rule filter_mutect_calls_tumor_only_pon:
    input :
        Mutect2_vcf = "Mutect2_Tp/{tsample}_PON_{panel_of_normal}_Tp.vcf.gz",
        Mutect2_stats = "Mutect2_Tp/{tsample}_PON_{panel_of_normal}_Tp.vcf.gz.stats",
        contamination_table = "cross_sample_contamination/{tsample}_calculatecontamination.table" ,
        panel_of_normal = "PoN/{panel_of_normal}.vcf",
    output:
        VCF   = temp("Mutect2_Tp/{tsample}_PON_{panel_of_normal}_filtered_Tp.vcf.gz"),
        INDEX = temp("Mutect2_Tp/{tsample}_PON_{panel_of_normal}_filtered_Tp.vcf.gz.tbi"),
    params:
        queue = "shortq",
        gatk = "/mnt/beegfs/software/gatk/4.1.4.1/gatk",
        # gatk  = config["gatk"]["app"],
        index = config["gatk"][config["samples"]]["genome_fasta"],
    log:
        "logs/filter_Mutect2_Tp/{tsample}_PON_{panel_of_normal}_filtered_Tp.vcf.gz.log"
    threads : 4
    resources:
        mem_mb = 10240
    shell:
        "{params.gatk} --java-options \"-Xmx10g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" FilterMutectCalls"
        " -V {input.Mutect2_vcf}"
        " -R {params.index}"
        " --contamination-table {input.contamination_table}"
        " -O {output.VCF} 2> {log}"

## A rule to filter VCF on orientation bias, for OxoG and FFPE, from mutect tumor only with PoN 
rule Filter_By_Orientation_Bias_tumor_only_pon:
    input :
        Mutect2_vcf = "Mutect2_Tp/{tsample}_PON_{panel_of_normal}_filtered_Tp.vcf.gz",
        pre_adapter_detail_metrics = "collect_Sequencing_Artifact_Metrics/{tsample}_artifact.pre_adapter_detail_metrics.txt",
    output:
        filtered_vcf       = "Mutect2_Tp/{tsample}_PON_{panel_of_normal}_twicefiltered_Tp.vcf.gz",
        filtered_vcf_index = "Mutect2_Tp/{tsample}_PON_{panel_of_normal}_twicefiltered_Tp.vcf.gz.tbi",
    params:
        queue= "shortq",
        gatk = "/mnt/beegfs/software/gatk/4.1.4.1/gatk",
    log:
        "logs/filter_Mutect2_Tp/{tsample}_PON_{panel_of_normal}_twicefiltered_Tp.vcf.gz.log"
    threads : 4
    resources:
        mem_mb = 10240
    shell:
        "{params.gatk} --java-options \"-Xmx10g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" FilterByOrientationBias"
        " -V {input.Mutect2_vcf}"
        " -AM G/T -AM C/T"
        " -P {input.pre_adapter_detail_metrics}"
        " -O {output.filtered_vcf} 2> {log}"  
        
