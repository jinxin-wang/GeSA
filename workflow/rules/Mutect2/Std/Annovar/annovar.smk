rule annovar_on_mutect:
    input:
        vcf = "Mutect2_TvN/{tsample}_vs_{nsample}_twicefiltered_TvN.vcf.gz"
    output:
        avinput = "annovar_mutect2_TvN/{tsample}_vs_{nsample}.avinput",
        txt = "annovar_mutect2_TvN/{tsample}_vs_{nsample}.mm9_multianno.txt",
        vcf = "annovar_mutect2_TvN/{tsample}_vs_{nsample}.mm9_multianno.vcf"
    params:
        queue = "mediumq",
        annovar = config["annovar"]["app"],
        annovar_db  = config["annovar"][config["samples"]]["DB"],
        annovar_ref = config["annovar"][config["samples"]]["ref"],
    threads : 8
    resources:
        mem_mb = 20480
    log:
        "logs/annovar/{tsample}_vs_{nsample}.log"
    shell :
       "{params.annovar} {input.vcf} {params.annovar_db}  --thread {threads} --maxgenethread 4 -buildver {params.annovar_ref} -out annovar_mutect2_TvN/{wildcards.tsample}_vs_{wildcards.nsample} -remove -protocol refGene,snp128 -operation g,f -nastring . -vcfinput 2> {log}"

