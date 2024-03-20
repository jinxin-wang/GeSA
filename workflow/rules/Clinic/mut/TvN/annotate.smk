# Add a filter for variants not in the intersection of all target files of the project.
rule somatic_maf_filter_outside_intersection:
    input:
        vcf="Mutect2_TvN/{tsample}_vs_{nsample}_twicefiltered_TvN.vcf.gz",
        bed=config["target_files"]["bed_padded"][config["general"]["bed_intersection"]],
    output:
        vcf=temp("calling/somatic_maf_filter_outside_intersection/{tsample}_vs_{nsample}.vcf.gz" ),
        tbi=temp("calling/somatic_maf_filter_outside_intersection/{tsample}_vs_{nsample}.vcf.gz.tbi" ),
    log:
        "logs/calling/somatic_maf_filter_outside_intersection/{tsample}_vs_{nsample}.log" 
    params:
        bedtools = "~/.conda/envs/metaprism_main/bin/bedtools",
        picard   = "~/.conda/envs/metaprism_main/bin/picard",
        bgzip    = "~/.conda/envs/metaprism_main/bin/bgzip",
        dir      = "calling/somatic_maf_filter_outside_intersection",
    threads: 1
    resources:
        queue="shortq",
        mem_mb=5000,
    shell:
        """
        header="{params.dir}/{wildcards.tsample}_vs_{wildcards.nsample}_header.vcf" ;
        inbed="{params.dir}/{wildcards.tsample}_vs_{wildcards.nsample}_content_inbed.vcf" ;
        offbed="{params.dir}/{wildcards.tsample}_vs_{wildcards.nsample}_content_offbed.vcf" ;
        offbed_ann="{params.dir}/{wildcards.tsample}_vs_{wildcards.nsample}_content_offbed_ann.vcf" ;
        
        {params.bedtools} intersect -a {input.vcf} -b {input.bed} -wa | sort | uniq > $inbed ;
        {params.bedtools} intersect -a {input.vcf} -b {input.bed} -v | sort | uniq > $offbed ;
        zgrep "^#" {input.vcf} > $header ;
        gawk 'BEGIN{{FS="\\t"; OFS="\\t"}} {{if ($7=="PASS") $7="OFF_TARGETS_INTERSECTION"; else $7="OFF_TARGETS_INTERSECTION;"$7; print}}' $offbed > $offbed_ann ;
        sed -i '3 i ##FILTER=<ID=OFF_TARGETS_INTERSECTION,Description='"\\"Variant is outside the bed file {input.bed}.\\""'>' $header ;
        cat $header $inbed $offbed_ann | {params.bgzip} -c > {output.vcf} && {params.picard} -Xmx4g SortVcf I={output.vcf} O={output.vcf} ;
        # rm $header $inbed $offbed $offbed_ann ;
        """

# Save VCF after all filtering.
# Extract a tab-delimited format file from the VCF with minimal information about the filters applied on variants.
rule somatic_maf_filters_vcf_to_table:
    input:
        vcf="calling/somatic_maf_filter_outside_intersection/{tsample}_vs_{nsample}.vcf.gz" ,
        tbi="calling/somatic_maf_filter_outside_intersection/{tsample}_vs_{nsample}.vcf.gz.tbi" 
    output:
        tsv_tmp_1=temp("calling/somatic_maf_filters/{tsample}_vs_{nsample}_tmp_1.tsv" ),
    log:
        "logs/calling/somatic_maf_filters_vcf_to_table/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_main"
    threads: 1
    params:
        gatk     = "~/.conda/envs/metaprism_main/bin/gatk",
        java_opt = "'-Xmx4g -Djava.io.tmpdir=/mnt/beegfs/scratch/tmp'",
    resources:
        queue="shortq",
        mem_mb=4000,
    shell:
        """
        module load java/17.0.4.1 ; 
        {params.gatk} --java-options {params.java_opt} VariantsToTable \
            -V {input.vcf} \
            -F CHROM -F POS -F REF -F ALT -F TYPE -F FILTER \
            --show-filtered \
            -O {output.tsv_tmp_1} 2> {log}
        """

rule somatic_maf_filters_process_fields:
    input:
        vcf="calling/somatic_maf_filter_outside_intersection/{tsample}_vs_{nsample}.vcf.gz" ,
        tbi="calling/somatic_maf_filter_outside_intersection/{tsample}_vs_{nsample}.vcf.gz.tbi" ,
        tsv_tmp_1="calling/somatic_maf_filters/{tsample}_vs_{nsample}_tmp_1.tsv" 
    output:
        vcf="calling/somatic_maf_filters/{tsample}_vs_{nsample}.vcf.gz" ,
        tbi="calling/somatic_maf_filters/{tsample}_vs_{nsample}.vcf.gz.tbi" ,
        tsv_tmp_2=temp("calling/somatic_maf_filters/{tsample}_vs_{nsample}_tmp_2.tsv" ),
        tsv="calling/somatic_maf_filters/{tsample}_vs_{nsample}.tsv.gz" 
    log:
        "logs/calling/somatic_maf_filters_process_fields/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_python"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
    params:
        python = "~/.conda/envs/metaprism_python/bin/python"
    shell:
        """
        cp {input.vcf} {output.vcf} && \
        cp {input.tbi} {output.tbi} && \
        {params.python} -u workflow/rules/Clinic/mut/TvN/scripts/utils_add_sample_ids.py \
            --input {input.tsv_tmp_1} \
            --tsample {wildcards.tsample} \
            --tlabel Tumor_Sample \
            --nsample {wildcards.nsample} \
            --nlabel Normal_Sample \
            --output {output.tsv_tmp_2} 2> {log} && \
        {params.python} -u workflow/rules/Clinic/mut/TvN/scripts/utils_remove_empty_fields.py  \
            --input {output.tsv_tmp_2} \
            --level 1 \
            --output {output.tsv} 2>> {log}
        """

# Extract only PASS variants for annotation afterwards.
rule somatic_maf_select_pass:
    input:
        vcf="calling/somatic_maf_filters/{tsample}_vs_{nsample}.vcf.gz" ,
        tbi="calling/somatic_maf_filters/{tsample}_vs_{nsample}.vcf.gz.tbi" 
    output:
        "calling/somatic_maf_select_pass/{tsample}_vs_{nsample}.vcf.gz" 
    log:
        "logs/calling/somatic_maf_select_pass/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_main"
    threads: 1
    params:
        gatk     = "~/.conda/envs/metaprism_main/bin/gatk",
        java_opt="'-Xmx4g -Djava.io.tmpdir=/mnt/beegfs/scratch/tmp'",
    resources:
        queue="shortq",
        mem_mb=4000,
    shell:
        """
        module load java/17.0.4.1
        {params.gatk} --java-options {params.java_opt} SelectVariants \
            --variant {input.vcf} \
            --exclude-filtered \
            --output {output} 2> {log}
        """

# Extract a tab-delimited format file from the VCF with minimal information about the filters applied on variants.
rule somatic_maf_filters_aggregate:
    input:
        expand("calling/somatic_maf_filters/{tsample}_vs_{nsample}.tsv.gz" , zip, tsample=tsamples, nsample=nsamples)
    output:
        # temp("aggregate/somatic_maf/somatic_calls_filters_prefinal.tsv.gz" )
        "aggregate/somatic_maf/somatic_calls_filters_prefinal.tsv.gz" 
    log:
        "logs/aggregate/somatic_maf/somatic_maf_filters_aggregate.log" 
    threads: 2
    conda:
        "metaprism_python"
    resources:
        queue="shortq",
        mem_mb=1000,
    shell:
        """
        zcat {input} | sed -n '1p;/^CHROM/ !p' | gzip > {output} 2> {log}
        """
####
#### Somatic mutations ####
####

# Run vep on somatic variants
# See https://www.ensembl.org/info/docs/tools/vep/script/vep_options.html#basic

# VEP with VCF output
rule somatic_vep_vcf:
    input:
        vcf="calling/somatic_maf_select_pass/{tsample}_vs_{nsample}.vcf.gz" ,
    output:
        vcf=temp("annotation/somatic_vep/{tsample}_vs_{nsample}.vcf" ),
    log:
        "logs/annotation/somatic_vep/{tsample}_vs_{nsample}_vep_vcf.log" 
    conda:
        "perl"
    params:
        species=config["ref"]["species"],
        vep_dir=config["params"]["vep"]["path"],
        vep_data=config["params"]["vep"]["cache"],
    threads: 4
    resources:
        queue="shortq",
        mem_mb=8000,
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


# VEP with Tab output
rule somatic_vep_tab:
    input:
        vcf="calling/somatic_maf_select_pass/{tsample}_vs_{nsample}.vcf.gz" ,
        cadd=config["params"]["vep"]["plugins_data"]["CADD"],
        dbnsfp=config["params"]["vep"]["plugins_data"]["dbNSFP"],
    output:
        vcf=temp("annotation/somatic_vep/{tsample}_vs_{nsample}.tsv" ),
    log:
        "logs/annotation/somatic_vep/{tsample}_vs_{nsample}_vep_tab.log" 
    conda:
        "perl"
    params:
        species=config["ref"]["species"],
        vep_dir=config["params"]["vep"]["path"],
        vep_data=config["params"]["vep"]["cache"],
        dbnsfp=",".join(config["params"]["vep"]["dbnsfp"])
    threads: 4
    resources:
        queue="shortq",
        mem_mb=10000,
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


# Convert VCF annotated by VEP to MAF format
rule somatic_vep_vcf2maf:
    input:
        "annotation/somatic_vep/{tsample}_vs_{nsample}.vcf" 
    output:
        temp("annotation/somatic_vep/{tsample}_vs_{nsample}.maf" )
    log:
        "logs/annotation/somatic_vep/{tsample}_vs_{nsample}_vcf2maf.log" 
    threads: 1
    conda:
        "perl"
    params:
        path  = config["params"]["vcf2maf"]["path"],
        fasta = "%s/%s"%(config["params"]["vep"]["cache"],config["params"]["vep"]["fasta"]),
        dbnsfp= ",".join(config["params"]["vep"]["dbnsfp"])
    resources:
        queue="shortq",
        mem_mb=4000,
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

# Merge the 2 tsv tables produced by VEP and by vcf2maf to produce final maf.
rule somatic_maf:
    input:
        vep="annotation/somatic_vep/{tsample}_vs_{nsample}.tsv" ,
        maf="annotation/somatic_vep/{tsample}_vs_{nsample}.maf" 
    output:
        "annotation/somatic_maf/{tsample}_vs_{nsample}.maf" 
    log:
        "logs/annotation/somatic_maf/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_python"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=8000,
    shell:
        """
        python -u workflow/rules/Clinic/mut/TvN/scripts/03.2_maf_merge_vep_and_maf.py \
            --vep_table {input.vep} \
            --maf_table {input.maf} \
            --keep_vep_header \
            --output {output} &> {log}
        """


# prepare a table for each pair tsample_vs_nsample
rule somatic_maf_civic:
    input:
        table_alt = "annotation/somatic_maf/{tsample}_vs_{nsample}.maf",
    output:
        table_pre = temp("annotation/somatic_maf_civic/{tsample}_vs_{nsample}_pre.tsv"),
        table_run = temp("annotation/somatic_maf_civic/{tsample}_vs_{nsample}_run.tsv"),
        table_pos = "annotation/somatic_maf_civic/{tsample}_vs_{nsample}.maf",
    log:
        "logs/annotation/somatic_maf_civic/{tsample}_vs_{nsample}.log"
    params:
        table_cln = config["general"]["tumor_normal_pairs"],
        table_gen = config["params"]["civic"]["gene_list"],
        civic     = config["params"]["civic"]["evidences"],
        rules     = config["params"]["civic"]["rules_clean"],
        code_dir  = config["params"]["civic"]["code_dir"],
        category  = "mut",
        a_option  = lambda wildcards, input: "-a %s" % input.table_alt
    threads: 1
    conda:
        "metaprism_python"
    resources:
        queue = "shortq",
        mem_mb= 4000,
    shell:
        """
        bash workflow/rules/Clinic/mut/TvN/scripts/04.3_civic_annotate.sh \
            {params.a_option} \
            -b {params.table_cln} \
            -c {params.table_gen} \
            -d {output.table_pre} \
            -e {output.table_run} \
            -f {output.table_pos} \
            -m {params.code_dir} \
            -n {params.civic} \
            -o {params.rules} \
            -t {params.category} \
            -l {log}
        """

# prepare a table for each pair tsample_vs_nsample
rule somatic_maf_oncokb:
    input:
        table_alt = "annotation/somatic_maf/{tsample}_vs_{nsample}.maf",
    output:
        table_alt_pre = temp("annotation/somatic_maf_oncokb/{tsample}_vs_{nsample}_alt_pre.tsv"),
        table_cln_pre = temp("annotation/somatic_maf_oncokb/{tsample}_vs_{nsample}_cln_pre.tsv"),
        table_run     = temp("annotation/somatic_maf_oncokb/{tsample}_vs_{nsample}_run.tsv"),
        table_pos     =      "annotation/somatic_maf_oncokb/{tsample}_vs_{nsample}.maf",
    log:
        "logs/annotation/somatic_maf_oncokb/{tsample}_vs_{nsample}.log"
    params:
        table_cln = config["general"]["tumor_normal_pairs"],
        table_gen = config["params"]["oncokb"]["gene_list"],
        rules     = config["params"]["oncokb"]["rules_clean"],
        token     = config["params"]["oncokb"]["token"],
        code_dir  = config["params"]["oncokb"]["code_dir"],
        category  = "mut",
        a_option  = lambda wildcards, input: "-a %s" % input.table_alt
    threads: 1
    conda:
        "metaprism_python"
    resources:
        queue = "shortq",
        mem_mb= 4000,
    shell:
        """
        bash workflow/rules/Clinic/mut/TvN/scripts/04.3_oncokb_annotate.sh \
            {params.a_option} \
            -c {params.table_gen} \
            -b {params.table_cln} \
            -d {output.table_alt_pre} \
            -g {output.table_cln_pre} \
            -e {output.table_run} \
            -f {output.table_pos} \
            -k {params.token} \
            -m {params.code_dir} \
            -o {params.rules} \
            -t {params.category} \
            -l {log}
        """

# Aggregate all somatic civic-annotated MAF tables.
rule somatic_maf_civic_aggregate:
    input:
        expand("annotation/somatic_maf_civic/{tsample}_vs_{nsample}.maf", zip, tsample=tsamples, nsample=nsamples),
        # expand("annotation/somatic_maf_civic/{tsample}_vs_{nsample}.maf", tsample=["MR1044_T"], nsample=["MR1044_N"]),
    output:
        "aggregate/somatic_maf/somatic_calls_civic_prefinal.maf.gz"
    log:
        "logs/annotation/somatic_maf/somatic_maf_civic_aggregate.log"
    threads: 1
    conda:
        "metaprism_python"
    resources:
        queue = "shortq",
        mem_mb= 16000,
    shell:
        """
        python -u workflow/rules/Clinic/mut/TvN/scripts/06.1_concatenate_tables.py \
            --files {input} \
            --output {output} &> {log}
        """

# Aggregate all somatic oncokb-annotated MAF tables.
rule somatic_maf_oncokb_aggregate:
    input:
        # expand("annotation/somatic_maf_oncokb/{tsample}_vs_{nsample}.maf", tsample=["MR1044_T"], nsample=["MR1044_N"]),
        # expand(SOMATIC_MAF_ONCOKB_MAF)
        expand("annotation/somatic_maf_oncokb/{tsample}_vs_{nsample}.maf", zip, tsample=tsamples, nsample=nsamples),
    output:
        "aggregate/somatic_maf/somatic_calls_oncokb_prefinal.maf.gz"
    log:
        "logs/annotation/somatic_maf/somatic_maf_oncokb_aggregate.log"
    threads: 1
    conda:
        "metaprism_python"
    resources:
        queue = "shortq",
        mem_mb= 16000,
    shell:
        """
        python -u workflow/rules/Clinic/mut/TvN/scripts/06.1_concatenate_tables.py \
            --files {input} \
            --output {output} &> {log}
        """

rule somatic_maf_union_ann:
    input:
        civ = "aggregate/somatic_maf/somatic_calls_civic_prefinal.maf.gz",
        okb = "aggregate/somatic_maf/somatic_calls_oncokb_prefinal.maf.gz",
    output:
        "aggregate/somatic_maf/somatic_calls_union_ann_prefinal.maf.gz"
    log:
        "logs/annotation/somatic_maf/somatic_maf_union_ann.log"
    resources:
        queue = "shortq",
        mem_mb = 8000,
    threads: 1
    conda:
        "metaprism_python"
    shell:
        """
        python -u workflow/rules/Clinic/mut/TvN/scripts/06.2_concatenate_annotations.py \
            --civ {input.civ} \
            --okb {input.okb} \
            --cat maf \
            --output {output} &> {log}
        """

# Aggregate all somatic MAF tables.
rule somatic_maf_aggregate:
    input:
        expand("annotation/somatic_maf/{tsample}_vs_{nsample}.maf", zip, tsample=tsamples, nsample=nsamples)
    output:
        # temp("aggregate/somatic_maf/somatic_calls_prefinal.maf.gz" )
        "aggregate/somatic_maf/somatic_calls_prefinal.maf.gz" 
    log:
        "logs/aggregate/somatic_maf/somatic_maf_aggregate.log" 
    threads: 1
    conda:
        "metaprism_python"
    resources:
        queue = "shortq",
        mem_mb=16000,
    shell:
        """
        python -u workflow/rules/Clinic/mut/TvN/scripts/06.1_concatenate_tables.py \
            --files {input} \
            --keep_header \
            --output {output} &> {log}
        """

# Apply last filtering steps
rule somatic_maf_last_filtering:
    input:
        filters="aggregate/somatic_maf/somatic_calls_filters_prefinal.tsv.gz",
        maf    ="aggregate/somatic_maf/somatic_calls_prefinal.maf.gz",
        maf_ann="aggregate/somatic_maf/somatic_calls_union_ann_prefinal.maf.gz",
        maf_civ="aggregate/somatic_maf/somatic_calls_civic_prefinal.maf.gz",
        maf_okb="aggregate/somatic_maf/somatic_calls_oncokb_prefinal.maf.gz"
    output:
        filters = "aggregate/somatic_maf/somatic_calls_filters.tsv.gz",
        maf     = "aggregate/somatic_maf/somatic_calls.maf.gz",
        maf_ann = "aggregate/somatic_maf/somatic_calls_union_ann.maf.gz",
        maf_civ = "aggregate/somatic_maf/somatic_calls_civic.maf.gz",
        maf_okb = "aggregate/somatic_maf/somatic_calls_oncokb.maf.gz"
    conda:
        "metaprism_python"
    log:
        "logs/aggregate/somatic_maf_last_filtering/somatic_maf_last_filtering.log" 
    resources:
        queue = "shortq",
        mem_mb=24000,
    threads: 1
    shell:
        """
        python -u workflow/rules/Clinic/mut/TvN/scripts/03.3_maf_last_filtering_steps.py \
            --inp_filters {input.filters} \
            --inp_maf {input.maf} \
            --inp_maf_ann {input.maf_ann} \
            --inp_maf_civ {input.maf_civ} \
            --inp_maf_okb {input.maf_okb} \
            --out_filters {output.filters} \
            --out_maf {output.maf} \
            --out_maf_ann {output.maf_ann} \
            --out_maf_civ {output.maf_civ} \
            --out_maf_okb {output.maf_okb} &> {log}
        """

