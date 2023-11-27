## Run somatic variant caller from GATK on all samples
rule HaplotypeCaller:
    input:
        bam = "bam/{sample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam",
        bai = "bam/{sample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam.bai",
    output:
        VCF = temp("haplotype_caller_tmp/{sample}_germline_variants_ON_{interval}.vcf.gz"),
        TBI = temp("haplotype_caller_tmp/{sample}_germline_variants_ON_{interval}.vcf.gz.tbi"),
    params:
        queue = "shortq",
        # gatk = config["gatk"]["app"],
        gatk = config["gatk"][config["samples"]]["app"],
        index = config["gatk"][config["samples"]]["genome_fasta"],
        gnomad_ref = config["gatk"][config["samples"]]["gnomad_ref"],
        interval = config["gatk"][config["samples"]][config["seq_type"]]["mutect_interval_dir"] + "/{interval}.bed",
    log:
        "logs/haplotype_caller_tmp/{sample}_germline_variants_ON_{interval}.vcf.log"
    threads : 4
    resources:
        mem_mb = 51200
    shell:
        "{params.gatk} --java-options \"-Xmx40g -XX:+UseParallelGC -XX:ParallelGCThreads={threads} -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" HaplotypeCaller"
        " --reference {params.index} "
        " -L {params.interval}"
        " -I {input.bam}"
        " --comp {params.gnomad_ref}"
        " --standard-min-confidence-threshold-for-calling 20"
        " -O {output.VCF} 2> {log}"
 
## Concatenate Haplotype caller temporary files
rule concatenate_haplotypecaller:
    input:
        vcfs = expand("haplotype_caller_tmp/{{nsample}}_germline_variants_ON_{mutect_interval}.vcf.gz", mutect_interval=mutect_intervals)
    output:
        concatened_vcf = temp("haplotype_caller/{nsample}_germline_variants.vcf.gz"),
        concatened_tbi = temp("haplotype_caller/{nsample}_germline_variants.vcf.gz.tbi"),
        vcf_liste      = temp("haplotype_tmp_list/{nsample}_haplotype_tmp_list.txt")
    params:
        queue = "shortq",
        # gatk = config["gatk"]["app"],
        gatk = config["gatk"][config["samples"]]["app"],
    threads : 1
    resources:
        mem_mb = 10240
    log:
        "logs/haplotype_caller/{nsample}_germline_variants.vcf.log"
    shell :
        "ls -1a haplotype_caller_tmp/{wildcards.nsample}_germline_variants_ON_*gz > haplotype_tmp_list/{wildcards.nsample}_haplotype_tmp_list.txt &&"
        "{params.gatk}  --java-options \"-Xmx8g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" MergeVcfs -I {output.vcf_liste} -O {output.concatened_vcf} 2> {log}"

## Filter somatic variant caller from GATK
rule HaplotypeCaller_filtering:
    input:
        VCF = "haplotype_caller/{sample}_germline_variants.vcf.gz",
        TBI = "haplotype_caller/{sample}_germline_variants.vcf.gz.tbi",
    output:
        VCF_SNP = temp("haplotype_caller_filtered/{sample}_germline_variants_snp.vcf.gz"),
        VCF_INDEL = temp("haplotype_caller_filtered/{sample}_germline_variants_indel.vcf.gz"),
        VCF_SNP_FILTERED = temp("haplotype_caller_filtered/{sample}_germline_variants_snp_filtered.vcf.gz"),
        VCF_INDEL_FILTERED = temp("haplotype_caller_filtered/{sample}_germline_variants_indel_filtered.vcf.gz"),
        VCF_SNP_TBI = temp("haplotype_caller_filtered/{sample}_germline_variants_snp.vcf.gz.tbi"),
        VCF_INDEL_TBI = temp("haplotype_caller_filtered/{sample}_germline_variants_indel.vcf.gz.tbi"),
        VCF_SNP_FILTERED_TBI = temp("haplotype_caller_filtered/{sample}_germline_variants_snp_filtered.vcf.gz.tbi"),
        VCF_INDEL_FILTERED_TBI = temp("haplotype_caller_filtered/{sample}_germline_variants_indel_filtered.vcf.gz.tbi"),
        VCF_FILTERED = "haplotype_caller_filtered/{sample}_germline_variants_filtered.vcf.gz",
        VCF_FILTERED_TBI = "haplotype_caller_filtered/{sample}_germline_variants_filtered.vcf.gz.tbi",
    params:
        queue = "shortq",
        # gatk = config["gatk"]["app"]
        gatk = config["gatk"][config["samples"]]["app"],
    log:
        "logs/haplotype_caller_filtered/{sample}_germline_variants_filtered.vcf.log"
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        "{params.gatk} --java-options \" -Xmx8g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" SelectVariants -V {input.VCF} -select-type SNP -O {output.VCF_SNP} 2>> {log} &&"
        " {params.gatk} --java-options \" -Xmx8g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" SelectVariants -V {input.VCF} -select-type MIXED -select-type INDEL -O {output.VCF_INDEL} 2>> {log} &&"
        " {params.gatk} --java-options \" -Xmx8g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" VariantFiltration -V {output.VCF_SNP} -filter \"QD < 2.0\" --filter-name \"QD2\" -filter \"QUAL < 30.0\" --filter-name \"QUAL30\" -filter \"SOR > 3.0\" --filter-name \"SOR3\" -filter \"FS > 60.0\" --filter-name \"FS60\" -filter \"MQ < 40.0\" --filter-name \"MQ40\" -filter \"MQRankSum < -12.5\" --filter-name \"MQRankSum-12.5\" -filter \"ReadPosRankSum < -8.0\" --filter-name \"ReadPosRankSum-8\" -O {output.VCF_SNP_FILTERED} 2>> {log} &&"
        " {params.gatk} --java-options \" -Xmx8g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" VariantFiltration -V {output.VCF_INDEL} -filter \"QD < 2.0\" --filter-name \"QD2\" -filter \"QUAL < 30.0\" --filter-name \"QUAL30\" -filter \"FS > 200.0\" --filter-name \"FS200\" -filter \"ReadPosRankSum < -20.0\" --filter-name \"ReadPosRankSum-20\" -O {output.VCF_INDEL_FILTERED} 2>> {log} && "
        " {params.gatk} --java-options \" -Xmx8g  -Djava.io.tmpdir=/mnt/beegfs/userdata/$USER/tmp \" MergeVcfs -I {output.VCF_INDEL_FILTERED} -I {output.VCF_SNP_FILTERED} -O {output.VCF_FILTERED} 2>> {log}"
        
