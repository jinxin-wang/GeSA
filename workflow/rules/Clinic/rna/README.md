Bug:

Initial state:
* $ ls prism/rna/Fusioncatcher/
ST2505  ST3259  ST3511  ST3733  ST4291  ST4300  ST4412  ST4451  ST4491

Error:
* FileNotFoundError: /mnt/beegfs/scratch/j_wang/03_Projects/STING/20230712_Human_RNAfusion_1.2.0/prism/rna/Fusioncatcher/ST4451-ARN

Correction:
* l prism/rna/Fusioncatcher
ST2505-ARN  ST3259-ARN  ST3511-ARN  ST3733-ARN  ST4291-ARN ST4300-ARN  ST4412-ARN  ST4451-ARN  ST4491-ARN

New Error:
* FileNotFoundError: /mnt/beegfs/scratch/j_wang/03_Projects/STING/20230712_Human_RNAfusion_1.2.0/prism/rna/Fusioncatcher/ST4451-ARN-ARN

Where does this `-ARN` comes from ? Why is it added by MetaPrism ?