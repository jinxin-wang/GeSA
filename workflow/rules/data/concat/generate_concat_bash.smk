rule generate_concat_bash:
    

    input: Sampes_metadata = 'Samples.csv'

    output: Concat_script = "concat_bash.sh"

    params:
        queue = "shortq",

    threads : 1
    conda: "python_env"
    resources:
        mem_mb = 5120
    log:
        "logs/"
    run:
        from pathlib import Path
        import pandas as pd
        import os
        import yaml
        with open("config.yaml") as f:
            download_config = yaml.load(f, Loader=yaml.FullLoader)
            Working_dir = download_config["Directories"]

        tgt_pwd = {Working_dir}/Sample_sheet.csv

        sample_df = pd.read_csv('Samples.csv')

        sample_grps = sample_df.groupby(['sampleId', 'protocol'])

        bash_script = ''
        for (sample_id, protocol), grp in sample_grps:
            r1 = grp['R1'].tolist()
            r2 = grp['R2'].tolist()
                
            bash_script += f"# Concatenation for ID={sample_id}, Type={protocol}, R1\n"
            concat_command_r1 = f'cat ' + ' '.join(r1) + ' > ' + tgt_pwd + sample_id + '_' + protocol + '_R1.fastq.gz\n'
            bash_script += concat_command_r1
            bash_script += f"# Concatenation for ID={sample_id}, Type={protocol}, R2\n"
            concat_command_r2 = f'cat ' + ' '.join(r2) + ' > ' + tgt_pwd + sample_id + '_' + protocol + '_R2.fastq.gz\n'
            bash_script += concat_command_r2


        with open('concatenation_script.sh', 'w') as script_file:
            script_file.write(bash_script)
        print("Bash script generated successfully!")
