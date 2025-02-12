#### suppose a such source directory in scratch:
####   {data_dir}/{common dir}/{sample_name}/**/{file_name}[1,2].fq.gz

rule concat_src_dir:
    input:
        raw_fastq_dir = config["raw_fastq_dir"],
    output:
        R1 = expand("%s/{sample}_1.fastq.gz"%config["concat_fastq_dir"], sample = SAMPLES),
        R2 = expand("%s/{sample}_2.fastq.gz"%config["concat_fastq_dir"], sample = SAMPLES),
    params:
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
            
        #### require python3
        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        logging.info(f"list of samples : \n%s"%("\n".join(SAMPLES)))

        logging.info(f"list of reads : \n%s"%("\n".join([ str(r) for r in reads_list])))
        
        for sample in SAMPLES:
            
            logging.info("build concat cmd for sample %s"%sample)
            
            r1_list = [ str(r) for r in reads_list[0::2] if r.parents[root_idx].joinpath(sample) == r.parents[root_idx-1] ] 
            r2_list = [ str(r) for r in reads_list[1::2] if r.parents[root_idx].joinpath(sample) == r.parents[root_idx-1] ]

            r1_list.sort()
            r2_list.sort()
            
            if is_all_match(r1_list, r2_list):
                logging.info("all match")
            else:
                logging.error(f"Reads 1: {r1_list} ")
                logging.error(f"Reads 2: {r2_list} ")
                raise Exception("Unable to match Reads 1 to Reads 2")

            os.system(f" mkdir -p {params.concat_fastq_dir} ")
            
            if len(r1_list) == 1:
                do_softlink(fastq_file=r1_list[0], concat_dir = params.concat_fastq_dir,
                            sample_id = sample, read12 = "1")
            else:
                do_concat(fastq_list = r1_list,    concat_dir = params.concat_fastq_dir,
                          sample_id = sample, read12 = "1")
                
            if len(r2_list) == 1:
                do_softlink(fastq_file=r2_list[0], concat_dir = params.concat_fastq_dir,
                            sample_id = sample, read12 = "2")
            else:
                do_concat(fastq_list = r2_list,    concat_dir = params.concat_fastq_dir,
                          sample_id = sample, read12 = "2")

        logging.info("Complete.")
                
