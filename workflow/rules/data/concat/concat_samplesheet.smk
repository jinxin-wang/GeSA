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
        queue = "shortq",
    threads: 4
    resources: 
        mem_mb = 51200
    log:
        out="logs/data/concat/concat_fastq_samplesheet.log"
    run:
        import os
        import sys
        import glob
        import logging
        import pandas as pd
        from pathlib import Path

        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

        #### require python3                                                                                                                                                                                  
        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        def is_match(r1: str, r2: str):
            read1, read2, flag = [*r1], [*r2], True
            for c1, c2 in zip(read1, read2):
                if c1 == c2 :
                    continue
                elif c1 == "1" and c2 == "2" and flag:
                    ## only difference should be 1 and 2, only once                                                                                                                                          
                    flag = False
                else:
                    return False
            return True

        sample_df = pd.read_csv(input.samplesheet, sep=',', header=0)
        sample_grps = sample_df.groupby(['sampleId', 'protocol'])

        logging.info(f"list of sample : \n%s"%("\n".join(sample_df.sampleId)))

        for (sample_id, protocol), grp in sample_grps:
            r1_list = grp['R1'].tolist()
            r2_list = grp['R2'].tolist()

            r1_list.sort()
            r2_list.sort()

            if len(r1_list) != len(r2_list):
                logging.error(f"matched list of R1 and R2 do NOT have same number of files.")
                logging.error(f"list of R1: \n%s"%("\n".join(r1_list)))
                logging.error(f"list of R2: \n%s"%("\n".join(r2_list)))

            for r1,r2 in zip(r1_list, r2_list):
                logging.info("Read 1 -- Read 2 pair:")
                logging.info("R1: %s "%(r1))
                logging.info("R2: %s "%(r2))
                
                if not is_match(r1, r2):
                    logging.error(f"R1: \n%s"%("\n".join(r1_list)))
                    logging.error(f"R2: \n%s"%("\n".join(r2_list)))                                                                                                                                          
                    raise Exception("R1 and R2 are NOT in corresponding order")

            r1_cmd = " ".join(["cat"] + r1_list + [">", "%s/%s_1.fastq.gz"%(params.concat_dir, sample_id)])

            logging.info(f"concat %s R1: \n%s"%(sample_id, r1_cmd))
            os.system(r1_cmd)
            logging.info("%s R1 done."%(sample_id))

            r2_cmd = " ".join(["cat"] + r2_list + [">", "%s/%s_2.fastq.gz"%(params.concat_dir, sample_id)])

            logging.info(f"concat %s R2: \n%s"%(sample_id, r2_cmd))
            os.system(r2_cmd)
            logging.info("%s R2 done."%(sample_id))

        logging.info("Complete.")
