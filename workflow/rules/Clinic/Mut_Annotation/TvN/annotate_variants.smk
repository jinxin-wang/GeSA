rule somatic_vep_vcf:
    input:
        vcf="Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz",
    output:
        vcf=temp("Vep/VCF_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz"),
    log:
        "logs/annotation/somatic_vep/{tsample}_vs_{nsample}_vep_vcf.log"
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/perl.yaml"
    params:
        species=metaprism_config["ref"]["species"],
        vep_dir=metaprism_config["params"]["vep"]["path"],
        vep_data=metaprism_config["params"]["vep"]["cache"],
    threads: 4
    resources:
        queue="shortq",
        mem_mb=8000,
        time_min=120
    shell:
        """
        {params.vep_dir}/vep  --input_file {input.vcf} \
            --dir {params.vep_data} \
            --cache \
            --canonical \
            --format vcf \
            --offline \
            --vcf \
            --no_progress \
            --no_stats \
            --af_gnomad \
            --appris \
            --sift b \
            --polyphen b \
            --biotype \
            --buffer_size 5000 \
            --hgvs \
            --species {params.species} \
            --symbol \
            --transcript_version \
            --output_file {output} \
            --warning_file {log}
        """



# VCF to MAF conversion, now the annotation is done.

rule somatic_vep_vcf2maf:
    input:
        "Vep/VCF_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz",
    output:
        temp("Vep/VCF_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.maf"),
    log:
        "logs/annotation/somatic_vep/{tsample}_vs_{nsample}_vcf2maf.log"
    threads: 1
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/perl.yaml"
    params:
        path=metaprism_config["params"]["vcf2maf"]["path"],
        fasta="%s/%s" % (metaprism_config["params"]["vep"]["cache"],metaprism_config["params"]["vep"]["fasta"]),
        dbnsfp=",".join(metaprism_config["params"]["vep"]["dbnsfp"])
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=20
    shell:
        """
        perl {params.path}/vcf2maf.pl \
            --inhibit-vep \
            --input-vcf {input} \
            --output {output} \
            --tumor-id {wildcards.tsample} \
            --normal-id {wildcards.nsample} \
            --ref-fasta {params.fasta} \
            --ncbi-build hg19 \
            --verbose 2> {log}
        """



# Use VEP-tab annotation, since the later VCF to TSV does not work properly
# without a previous VEP annotation

rule somatic_vep_tab:
    input:
        vcf="Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz",
        cadd=metaprism_config["params"]["vep"]["plugins_data"]["CADD"],
        dbnsfp=metaprism_config["params"]["vep"]["plugins_data"]["dbNSFP"],
    output:
        vcf=temp("Vep/TAB_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.tsv"),
    log:
        "logs/annotation/somatic_vep/{tsample}_vs_{nsample}_vep_tab.log"
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/perl.yaml"
    params:
        species=metaprism_config["ref"]["species"],
        vep_dir=metaprism_config["params"]["vep"]["path"],
        vep_data=metaprism_config["params"]["vep"]["cache"],
        dbnsfp=",".join(metaprism_config["params"]["vep"]["dbnsfp"])
    threads: 4
    resources:
        queue="shortq",
        mem_mb=10000,
        time_min=120
    shell:
        """
        {params.vep_dir}/vep  --input_file {input.vcf} \
            --dir {params.vep_data} \
            --cache \
            --canonical \
            --format vcf \
            --offline \
            --tab \
            --no_progress \
            --no_stats \
            --max_af \
            --af_gnomad \
            --sift b \
            --polyphen b \
            --appris \
            --biotype \
            --buffer_size 5000 \
            --hgvs \
            --mane \
            --species {params.species} \
            --symbol \
            --numbers \
            --transcript_version \
            --plugin CADD,{input.cadd[0]},{input.cadd[1]} \
            --plugin dbNSFP,{input.dbnsfp},{params.dbnsfp} \
            --output_file {output} \
            --warning_file {log}
        """


# Merge somatic VEP-Tab and VEP-MAF in a final MAF.
# This is required for ulterior annotation.
rule somatic_maf:
    input:
        vep="Vep/TAB_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.tsv",
        maf="Vep/VCF_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.maf",
        script_path="/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/scripts/03.2_maf_merge_vep_and_maf.py"
    output:
        temp("MAF/annotation/somatic_maf/{tsample}_Vs_{nsample}.maf"),
    log:
        "logs/annotation/somatic_maf/{tsample}_vs_{nsample}.log"
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/python.yaml"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=20
    shell:
        """
        python -u {input.script_path} \
            --vep_table {input.vep} \
            --maf_table {input.maf} \
            --keep_vep_header \
            --output {output} &> {log}
        """


rule somatic_maf_civic:
    input:
        table_alt="MAF/annotation/somatic_maf/{tsample}_Vs_{nsample}.maf",
        table_cln=metaprism_config["tumor_normal_pairs"],
        table_gen=metaprism_config["params"]["civic"]["gene_list"],
        civic=metaprism_config["params"]["civic"]["evidences"],
        rules=metaprism_config["params"]["civic"]["rules_clean"],
        script_path="/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/scripts/04.3_civic_annotate.sh"
    output:
        table_pre=temp("MAF/annotation/civic_db/{tsample}_Vs_{nsample}_pre.tsv"),
        table_run=temp("MAF/annotation/civic_db/{tsample}_Vs_{nsample}_run.tsv"),
        table_pos="MAF/annotation/civic_db/{tsample}_Vs_{nsample}_pos.tsv",
    log:
        "logs/annotation/somatic_maf_civic/{tsample}_vs_{nsample}.log"
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/python.yaml"
    params:
        code_dir=metaprism_config["params"]["civic"]["code_dir"],
        category="mut",
        a_option=lambda wildcards, input: "-a %s" % input.table_alt
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=20
    shell:
        """
        bash {input.script_path} \
            {params.a_option} \
            -b {input.table_cln} \
            -c {input.table_gen} \
            -d {output.table_pre} \
            -e {output.table_run} \
            -f {output.table_pos} \
            -m {params.code_dir} \
            -n {input.civic} \
            -o {input.rules} \
            -t {params.category} \
            -l {log}
        """
