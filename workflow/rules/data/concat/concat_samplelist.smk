#### suppose a such source directory in scratch:
####   {data_dir}/{sample_name}/{file_name}[1,2].fq.gz
rule concat_samplelist:
    input:
        raw_fastq_dir = config["raw_fastq_dir"],
    output:
        R1 = expand("%s/{sample}_1.fastq.gz"%config["concat_fastq_dir"], sample = SAMPLES),
        R2 = expand("%s/{sample}_2.fastq.gz"%config["concat_fastq_dir"], sample = SAMPLES),
    params:
        samples  = SAMPLES,
        reads_patterns = config["reads_patterns"],
        concat_fastq_dir = config["concat_fastq_dir"],
    threads: 1
    resources: 
        mem_mb = 10240,
        queue  = "shortq",
        time_min = dataset_size,
        disk_mb  = dataset_size * 1024,
    log:
        out="logs/data/concat/concat_bash_from_dir.log"
    run:
        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        logging.info(f"list of sample : \n%s"%("\n".join(params.samples)))

        for sample in params.samples:
            
            logging.info("build concat cmd for sample %s"%sample)
            
            reads_list = []
            for pattern in params.reads_patterns:
                pattern = f"{input.raw_fastq_dir}/**/{sample}/**/{pattern}"
                logging.info("matching pattern: {pattern}")
                reads_list.extend(glob.glob(pattern, recursive = True))

            if len(reads_list) == 0:
                raise Exception("Unable to find fastq files")
            
            reads_list.sort()
            r1_list = reads_list[0::2]
            r2_list = reads_list[1::2]
            
            if is_all_match(r1_list, r2_list):
                logging.info("all matches")
            else:
                logging.error(f"Reads 1: {r1_list} ")
                logging.error(f"Reads 2: {r2_list} ")
                raise Exception("Unable to match Reads 1 to Reads 2")

            os.system(f" mkdir -p {params.concat_fastq_dir} ")
            
            if len(r1_list) == 1:
                do_softlink(fastq_file=r1_list[0], concat_dir = params.concat_fastq_dir,
                            sample_id = sample, read12 = "1")
            else:
                do_concat(fastq_list = r1_list, concat_dir = params.concat_fastq_dir,
                          sample_id = sample, read12 = "1")
                
            if len(r2_list) == 1:
                do_softlink(fastq_file=r2_list[0], concat_dir = params.concat_fastq_dir,
                            sample_id = sample, read12 = "2")
            else:
                do_concat(fastq_list = r2_list, concat_dir = params.concat_fastq_dir,
                          sample_id = sample, read12 = "2")

        logging.info("Complete.")
                
