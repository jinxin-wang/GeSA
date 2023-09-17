rule check_md5sum_abstract:
    input:
        "md5sum.txt",
    output:
        "md5sum.log",
    params:
        queue = "shortq",
    threads : 4
    resources:
        mem_mb = 51200
    shell :
        " md5sum -c {input} > {output} "
