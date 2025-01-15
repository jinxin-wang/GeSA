# https://github.com/Illumina/manta/blob/master/docs/userGuide/README.md#somatic-configuration-examples
rule sv_manta_TvN:
    input:
        tbam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        nbam = "bam/{nsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{nsample}.recal.bam",
        tbai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",        
        nbai = "bam/{nsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{nsample}.recal.bam.bai",        
    output:
        path= "sv_manta_TvN"
        maf = "sv_manta_TvN/{tsample}_vs_{nsample}.manta.maf",
    log:
        "logs/sv_manta_TvN/{tsample}_vs_{nsample}.log" 
    conda:
        "manta"
    params:
        queue = "shortq",
        manta = config["manta"]["script"],
        ref   = config[""]["ref"],
    threads: 1
    resources:
        queue  = "shortq",
        mem_mb = 4096,
    shell:
        """
        python -u {params.manta} \
            --normalBam {input.nbam} \
            --tumorBam  {input.tbam} \
            --referenceFasta {params.ref} \
            --runDir ${output.path}
        """

rule sv_manta_T:
    input:
        tbam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        tbai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",        
    output:
        path= "sv_manta_T"
        maf = "sv_manta_T/{tsample}_vs_{nsample}.manta.maf",
    log:
        "logs/sv_manta_T/{tsample}_vs_{nsample}.log" 
    conda:
        "manta"
    params:
        queue = "shortq",
        manta = config["manta"]["script"],
        ref   = config[""][""],
    threads: 1
    resources:
        queue  = "shortq",
        mem_mb = 4096,
    shell:
        """
        python -u {params.manta} \
            --tumorBam  {input.tbam} \
            --referenceFasta {params.ref} \
            --runDir ${output.path}
        """
