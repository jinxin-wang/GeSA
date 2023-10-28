# Snakemake:  WGS/WES analysis pipeline for human/mouse samples

[![Snakemake](https://img.shields.io/badge/snakemake-=5.23.0-brightgreen.svg)](https://snakemake.github.io)

#### Usage On flamingo

- Step 0. clone github workflow project on flamingo or update the code
```
$ ssh username@flamingo.intra.igr.fr
$ git clone https://github.com/jinxin-wang/Genome_Sequencing_Analysis.git

or

$ git pull
```
- Step 1. create conda envirements 
```
$ conda create -f ./Genome_Sequencing_Analysis/workflow/envs/META_PRISM_conda_env.txt -n meta_prism
$ conda create -f ./Genome_Sequencing_Analysis/workflow/envs/Mouse_env.txt -n Mouse
$ conda create -f ./Genome_Sequencing_Analysis/workflow/envs/pipeline_GATK_2.1.4_conda_env.txt -n pipeline_GATK_2.1.4_V2
```

If the directory of your conda lib is not ~/.conda/, then 
```
$ cd
$ ln -s "your_conda_lib_dir" .conda
```
Or link the environments to ~/.conda/envs (if you already have this folder in ~/.conda/). For example:
```
ln -s "/mnt/beegfs/userdata/${USER}/conda/miniconda/envs/pipeline_GATK_2.1.4_V2/" .conda/envs
ln -s "/mnt/beegfs/userdata/${USER}/conda/miniconda/envs/Mouse/" .conda/envs
ln -s "/mnt/beegfs/userdata/${USER}/conda/miniconda/envs/meta_prism/" .conda/envs
```

- Step 2. deploy workflow

Create a directory for your project, then create soft links to your datasets in the directory DNA_samples. Please make sure 
that the pattern of files name is {file_name}_[012].fastq.gz. Moreover, keep in mind that the softlinks should be always accessible on the work nodes.

```
$ cd /mnt/beegfs/scratch/username/yourprojectdir
$ mkdir projectname; cd !$
$ ln -s /workflowpath/workflow .
$ cp /workflowpath/run.sh .
$ mkdir -p DNA_samples; cd !$
$ ln -s /datadir/* .
```
- Step 3. configure workflow

1. If there are both tumor samples and normal samples, then you need create a file **variant_call_list_TvN.tsv** in the project directory. The first column is the name of tumor samples, and second column is for normal samples. Each row is a tumor vs normal pair. The seperator is tab. 

2. If there are both tumor samples and panel of normal samples, then you need create a file **variant_call_list_Tp.tsv** in the project directory.

3. If there are tumor, normal samples and panel of normal samples, then you need create a file **variant_call_list_TvNp.tsv** in the project directory.

4. If there are only tumor samples, then you don't need to generate any tsv file. Or you can create a file **variant_call_list_T.tsv** in the project directory.

Then, you need to modify the bash file run.sh. For example, if you need to run WES pipeline for mice samples in tumor vs normal mode, then the options in the --config should modified as follow. If you don't set the values, then the default values will be taken. The default value of samples is human, and for seq_type is WGS, for mode is TvN 

```
$ cd /mnt/beegfs/scratch/username/yourprojectdir/projectname
$ emacs -nw variant_call_list_TvN.tsv
$ cat variant_call_list_TvN.tsv
tumor_sample_A  normal_sample_A
tumor_sample_B  normal_sample_B
$ emacs -nw run.sh
snakemake -c 'sbatch --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --rerun-incomplete --config samples=mouse seq_type=WES mode=TvN
```
- Step 4. run workflow
```
$ ./run.sh
[message] Loading configuration file
[message] Starting WES analysis pipeline for mouse samples
[message] Pipeline runs in Tumor vs Normal mode.
[message] Configuration file variant_call_list_TvN.tsv is detected.
Building DAG of jobs...
Using shell: /usr/bin/bash
Provided cluster nodes: 20
Job counts:
	count	jobs
....
....
....
```

[Examples of Best Practice](https://snakemake.github.io/snakemake-workflow-catalog/)

![alt text](https://github.com/jinxin-wang/Genome_Sequencing_Analysis/blob/andrei_modi_final/utils/images/DNA_Routine_Pipeline.png)
