rule generate_concat_bash_from_samplesheet:
    input: 
        Sampes_metadata = config["sample_sheet"],
    output:
        Concat_script   = config["concat_script"],
    params:
        queue = "shortq"
    threads : 4
    resources:
        mem_mb = 51200
    run:
        from pathlib import Path
        import pandas as pd
        import os

        sample_df = pd.read_csv(input.Sampes_metadata, sep=',', header=0)

        sample_grps = sample_df.groupby(['sampleId', 'protocol'])

        bash_script = ''
        for (sample_id, protocol), grp in sample_grps:
            r1 = grp['R1'].tolist()
            r2 = grp['R2'].tolist()
                
            bash_script += f"# Concatenation for ID={sample_id}, Type={protocol}, Read 1\n"
            concat_command_r1 = f'cat ' + ' '.join(r1) + ' > ' + tgt_pwd + sample_id + '_' + protocol + '_1.fastq.gz\n'
            bash_script += concat_command_r1
            bash_script += f"# Concatenation for ID={sample_id}, Type={protocol}, Read 2\n"
            concat_command_r2 = f'cat ' + ' '.join(r2) + ' > ' + tgt_pwd + sample_id + '_' + protocol + '_2.fastq.gz\n'
            bash_script += concat_command_r2

        with open(output.Concat_script.sh, 'w') as script_file:
            script_file.write(bash_script)

        print("Bash script generated successfully!")


