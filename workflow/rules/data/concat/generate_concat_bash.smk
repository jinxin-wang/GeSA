rule generate_concat_bash:
    input: 
        Sampes_metadata = config["general"]["SampleSheet"],
    output:
        Concat_script = config["general"]["ConcatScript"],
    params:
        group_attrs = config[config["general"]["DownloadResource"]]["GroupByAttrs"],
        tgt_pwd     = config["general"]["ConcatPath"],
        queue = "shortq",
    threads : 1
    resources:
        mem_mb = 5120
    log:
        "logs/"
    run:
        from pathlib import Path
        import pandas as pd

        sample_df = pd.read_csv(input.Sampes_metadata, sep='\t', header=0)

        sample_grps = sample_df.groupby(params.group_attrs)

        bash_script = ''

        for (sample_id, protocol), grp in sample_grps:

            sample_id = sample_id.split('|')[0].strip().replace("-","_").replace(" ", "_")
            
            r1 = grp['R1'].tolist()
            r2 = grp['R2'].tolist()
                
            bash_script += f"# Concatenation for ID={sample_id}, Type={protocol}, R1\n"
            concat_command_r1 = f'cat ' + ' '.join(r1) + ' > ' + params.tgt_pwd + sample_id + '_' + protocol + '_R1.fastq.gz\n'
            bash_script += concat_command_r1
            bash_script += f"# Concatenation for ID={sample_id}, Type={protocol}, R2\n"
            concat_command_r2 = f'cat ' + ' '.join(r2) + ' > ' + params.tgt_pwd + sample_id + '_' + protocol + '_R2.fastq.gz\n'
            bash_script += concat_command_r2


        with open(output.Concat_script, 'w') as script_file:
            script_file.write(bash_script)


rule exec_concat_bash:
    input:
        Concat_script = config["general"]["ConcatScript"],
