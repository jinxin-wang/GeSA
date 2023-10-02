## A rule to clean fastq files with fastp SE
if config["paired"] == False:
    rule fastp_SE:
        input:
            fastq_0="DNA_samples/{sample}_0.fastq.gz",
        output:
            fastq_clean = temp('DNA_samples_clean/{sample}_0.fastq.gz'),
            html_report = 'fastp_reports/{sample}_fastp_report.html',
            json_report = 'fastp_reports/{sample}_fastp_report.json'
        log:
            "logs/fastp/{sample}_fastp.html.log"
        params:
            queue = "mediumq",
            fastp = config["fastp"]["app"],
            adapters = config["fastp"]["adapters"]
        threads : 32
        resources:
            mem_mb = 102400
        run:
            print("[Message: rule fastp] Clean fastq files with fastp single read.")
            shell('{params.fastp} --thread {threads} --dont_overwrite -i {input.fastq_0} -o {output.fastq_clean} --compression 9 --adapter_fasta {params.adapters} --trim_poly_g --trim_poly_x --length_required 25 --overrepresentation_analysis  --html {output.html_report} --json {output.json_report} 2> {log}')

## A rule to clean fastq files with fastp PE
elif config["paired"] == True:
    rule fastp_PE:
        input:
            fastq_1="DNA_samples/{sample}_1.fastq.gz",
            fastq_2="DNA_samples/{sample}_2.fastq.gz",
        output:
            fastq_clean_1 = temp('DNA_samples_clean/{sample}_1.fastq.gz'),
            fastq_clean_2 = temp('DNA_samples_clean/{sample}_2.fastq.gz'),
            html_report   = 'fastp_reports/{sample}_fastp_report.html',
            json_report   = 'fastp_reports/{sample}_fastp_report.json'
        log:
            "logs/fastp/{sample}_fastp.html.log"
        params:
            queue = "longq",
            fastp = config["fastp"]["app"],
            adapters = config["fastp"]["adapters"]
        threads : 32
        resources:
            mem_mb = 102400
        run:
            print("[Message: rule fastp] Clean fastq files with fastp paired-end.")
            shell('{params.fastp} --thread {threads} --dont_overwrite -i {input.fastq_1} -o {output.fastq_clean_1} -I {input.fastq_2} -O {output.fastq_clean_2} --compression 9 --adapter_fasta {params.adapters} --trim_poly_g --trim_poly_x --length_required 25 --overrepresentation_analysis  --html {output.html_report} --json {output.json_report} 2> {log}')

else: 
    print("[Message: rule fastp] Unable to recognize the configuration value of 'paired': %s"%(str(config["paired"])))
