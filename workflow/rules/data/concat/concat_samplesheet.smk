#### suppose a sample sheet is provided with the following columns
#### 'sampleId', 'protocol', 'R1', 'R2', 
#### {data_dir}/{sample_name}/{file_name}[1,2].fq.gz
rule concat_samplesheet:
    input:
        samplesheet  = config["sample_sheet"],
    output:
        R1 = expand("%s/{sample}_1.fastq.gz"%config["concat_fastq_dir"], sample = SAMPLES),
        R2 = expand("%s/{sample}_2.fastq.gz"%config["concat_fastq_dir"], sample = SAMPLES),
    params:
        concat_dir = config["concat_fastq_dir"],
    threads: 1
    resources: 
        mem_mb = 10240,
        queue  = "mediumq",
        time_min = dataset_size,
        disk_mb  = dataset_size * 1024,
    log:
        out="logs/data/concat/concat_fastq_samplesheet.log"
    run:
        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        sample_df = pd.read_csv(input.samplesheet, sep=',', header=0)
        sample_grps = sample_df.groupby(['sampleId', 'protocol'])

        logging.info(f"list of sample : \n%s"%("\n".join(sample_df.sampleId)))
        
        os.system(f" mkdir -p {params.concat_fastq_dir} ")

        for (sample_id, protocol), grp in sample_grps:
            r1_list = grp['R1'].tolist()
            r2_list = grp['R2'].tolist()

            r1_list.sort()
            r2_list.sort()

            if is_all_match(r1_list, r2_list):
                logging.info("all matches")

            do_concat(fastq_list = r1_list, concat_dir = input.concat_fastq_dir,
                      sample_id = sample_id, read12 = "1")
            
            do_concat(fastq_list = r2_list, concat_dir = input.concat_fastq_dir,
                      sample_id = sample_id, read12 = "2")

        logging.info("Complete.")
