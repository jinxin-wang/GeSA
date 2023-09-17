#### suppose a such source directory in scratch:
####   {data_dir}/{sample_name}/{file_name}[1,2].fq.gz
rule concat_bash_from_dir:
    input:
        raw_fastq_dir    = config["raw_fastq_dir"],
        concat_fastq_dir = config["concat_fastq_dir"],
    output:
        R1 = expand("%s/{sample}_1.fastq.gz"%config["concat_fastq_dir"], sample = NSAMPLE + TSAMPLE),
        R2 = expand("%s/{sample}_2.fastq.gz"%config["concat_fastq_dir"], sample = NSAMPLE + TSAMPLE),
    params:
        queue    = "shortq",
        tsamples = TSAMPLE,
        nsamples = NSAMPLE,
        r1_pattern  = config["concat_r1_pattern"],
        r2_pattern  = config["concat_r2_pattern"],
    threads: 4
    resources: 
        mem_mb = 51200
    run:
        import os
        import sys
        import glob
        import logging
        import subprocess

        #### require python3
        if sys.version_info.major < 3:
            logging.warning("[WARNING] require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))
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
                        
        def do_cmds(samples_list):
                
            for sample in samples_list:
                    
                logging.info("[INFO] build concat cmd for sample %s"%sample)
                    
                r1_list = glob.glob("%s/%s/%s"%(input.raw_fastq_dir, sample, params.r1_pattern))
                r2_list = glob.glob("%s/%s/%s"%(input.raw_fastq_dir, sample, params.r2_pattern))

                if len(r1_list) != len(r2_list):
                    logging.error(f"[ERROR] matched list of R1 and R2 do NOT have same number of files. \n\n")
                    logging.error(f"R1: \n%s\n"%("\n".join(r1_list)))
                    logging.error(f"R2: \n%s\n"%("\n".join(r2_list)))

                for r1,r2 in zip(r1_list, r2_list):
                    logging.info("[INFO] R1: %s -- R2: %s"%(r1,r2))
                    if not is_match(r1, r2):
                        raise Exception("[ERROR] R1 and R2 are NOT in corresponding order")

                logging.info("[INFO] R1 and R2 are in corresponding order")

                r1_cmd = ["cat"] + r1_list + [">", "%s/%s_1.fastq.gz"%(input.concat_fastq_dir,sample)]
                logging.info(f"[INFO] concat R1: \n%s\n"%(" ".join(r1_cmd)))
                subprocess.run(r1_cmd)
                
                r2_cmd = ["cat"] + r2_list + [">", "%s/%s_2.fastq.gz"%(input.concat_fastq_dir,sample)]
                logging.info(f"[INFO] concat R2: \n%s\n"%(" ".join(r2_cmd)))
                subprocess.run(r2_cmd)

        do_cmds(params.nsamples)
        do_cmds(params.tsamples)
                
