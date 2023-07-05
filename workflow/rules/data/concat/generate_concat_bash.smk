rule generate_concat_bash:
    input: 
        Sampes_metadata = config["general"]["SampleSheet"],
    output:
        Concat_script = config["concat"]["ConcatScript"],
    params:
        group_attrs = config[config["general"]["DownloadResource"]]["SampleSheetAttrs"],
        tgt_pwd     = config["general"]["ConcatPath"],
        queue = "shortq",
    threads : 1
    resources:
        mem_mb = 5120
    run:
        from pathlib import Path
        import pandas as pd

        def sf(s): 
            return s.strip().replace("-","_").replace(" ", "_")

        sample_df = pd.read_csv(input.Sampes_metadata, sep='\t', header=0)

        sample_grps = sample_df.groupby(params.group_attrs)

        bash_script = ''

        for (sample_id, protocol, sample_type), grp in sample_grps:

            sample_id = sf(sample_id.split('|')[0])
            protocol  = sf(protocol)
            sample_type = sf(sample_type)
            
            r1 = grp['R1'].tolist()
            r2 = grp['R2'].tolist()
                
            bash_script += f"# Concatenation for ID={sample_id}, Type={protocol}, R1\n"
            r1_name = sample_id + '_' + sample_type + '_R1.fastq.gz'
            r2_name = sample_id + '_' + sample_type + '_R2.fastq.gz'
            mkdir_cmd = "mkdir -p %s \n "%Path(params.tgt_pwd).joinpath(protocol)
            bash_script += mkdir_cmd
            concat_cmd_r1 = "cat %s  > %s \n "%(' '.join(r1), Path(params.tgt_pwd).joinpath(protocol).joinpath(r1_name))
            bash_script += concat_cmd_r1
            bash_script += f"# Concatenation for ID={sample_id}, Type={protocol}, R2\n"
            concat_cmd_r2 = "cat %s  > %s \n "%(' '.join(r2), Path(params.tgt_pwd).joinpath(protocol).joinpath(r2_name))
            bash_script += concat_cmd_r2

        with open(output.Concat_script, 'w') as script_file:
            script_file.write(bash_script)
            


rule exec_concat_bash:
    input:
        Concat_script = config["Concat"]["ConcatScript"],
    output:
        Concat_success = config["Concat"]["ConcatSuccess"],
    log: 
        "logs/data/exec_concat_bash.log"
    params:
        group_attrs = config[config["general"]["DownloadResource"]]["SampleSheetAttrs"],
        tgt_pwd     = config["general"]["ConcatPath"],
        queue       = "shortq",
    threads : 1
    resources:
        mem_mb = 5120
    shell:
        """
        bash {input.Concat_script} 2> {log} && touch {output.Concat_success}
        """
