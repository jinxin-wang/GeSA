## Annovar on Haplotype caller 
rule annovar:
    input:
        vcf = "haplotype_caller_filtered/{sample}_germline_variants_filtered.vcf.gz"
    output:
        avinput = temp("annovar/{sample}.avinput"),
        txt     = temp("annovar/{sample}.%s_multianno.txt"%config["annovar"][config["samples"]]["ref"]),
        vcf     = temp("annovar/{sample}.%s_multianno.vcf"%config["annovar"][config["samples"]]["ref"]),
    params:
        queue    = "shortq",
        annovar  = config["annovar"]["app"],
        DB       = config["annovar"][config["samples"]]["DB"],
        ref      = config["annovar"][config["samples"]]["ref"],
        protocol = config["annovar"][config["samples"]]["protocols"],
        operation= config["annovar"][config["samples"]]["operations"],
    threads : 16
    resources:
        mem_mb = 10240
    log:
        "logs/annovar/{sample}.log"
    shell :
        "{params.annovar} {input.vcf} {params.DB} "
        " --thread {threads} --maxgenethread 8 "
        " -buildver {params.ref} "
        " -out annovar/{wildcards.sample} "
        " -remove "
        " -protocol {params.protocol} "
        " -operation {params.operation} "
        " -nastring . -vcfinput 2> {log} "

include: "rules/data/utils/gz.smk"

use rule compr_with_gzip_abstract as annovar_gzip with:
    input:
        "annovar/{sample}.%s_multianno.txt"%config["annovar"][config["samples"]]["ref"],
    output:
        "annovar/{sample}.%s_multianno.txt.gz"%config["annovar"][config["samples"]]["ref"],
