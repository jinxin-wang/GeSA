#### suppose a such source directory in scratch:
####   {data_dir}/{sample_name}/{file_name}[1,2].fq.gz
rule concat_src_dir:
    input:
        raw_fastq_dir    = config["raw_fastq_dir"],
        concat_fastq_dir = config["concat_fastq_dir"],
    output:
        R1 = expand("%s/{sample}_1.fastq.gz"%config["concat_fastq_dir"], sample = SAMPLES),
        R2 = expand("%s/{sample}_2.fastq.gz"%config["concat_fastq_dir"], sample = SAMPLES),
    params:
        queue    = "shortq",
        samples  = SAMPLES,
        r1_pattern  = config["concat_r1_pattern"],
        r2_pattern  = config["concat_r2_pattern"],
    threads: 4
    resources: 
        mem_mb = 51200
    log:
        out="logs/data/concat/concat_bash_from_dir.log"
    run:
        #### require python3
        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)
        
            
        logging.info(f"list of sample : \n%s"%("\n".join(params.samples)))

        for sample in params.samples:
                    
            logging.info("build concat cmd for sample %s"%sample)
                    
            r1_list = glob.glob("%s/%s/%s"%(input.raw_fastq_dir, sample, params.r1_pattern))
            r2_list = glob.glob("%s/%s/%s"%(input.raw_fastq_dir, sample, params.r2_pattern))

            r1_list.sort()
            r2_list.sort()

            if is_all_match(r1_list, r2_list):
                logging.info("all matches")

            do_concat(fastq_list = r1_list, concat_dir = input.concat_fastq_dir,
                      sample_id = sample, read12 = "1")
            
            do_concat(fastq_list = r2_list, concat_dir = input.concat_fastq_dir,
                      sample_id = sample, read12 = "2")

        logging.info("Complete.")
                
