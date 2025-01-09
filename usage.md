# DNA routine analysis for human/mouse samples

[![Snakemake](https://img.shields.io/badge/snakemake-=5.23.0-brightgreen.svg)](https://snakemake.github.io)

#### Usage On flamingo

- Step 0. check if the pipeline is accessible for you on flamingo

```
$ ssh username@flamingo.intra.igr.fr
$ ll /mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/
total 6,5K
-rw-r--r-- 1 j_wang gs_hpc_u981 1,1K 17 nov.  15:24 LICENSE
-rw-r--r-- 1 j_wang gs_hpc_u981 3,8K 17 nov.  15:26 README.md
drwxr-xr-x 6 j_wang gs_hpc_u981   12 17 nov.  19:18 utils
drwxr-xr-x 7 j_wang gs_hpc_u981    6 17 nov.  15:26 workflow

```

- Step 1. ln to working conda envirements 

```
$ ln -s /mnt/beegfs/userdata/j_wang/.conda/envs/routine your_conda_dir/envs/
$ ln -s /mnt/beegfs/userdata/j_wang/.conda/envs/meta_prism* your_conda_dir/envs/
$ ln -s /mnt/beegfs/userdata/j_wang/.conda/envs/Mouse your_conda_dir/envs/Mouse
$ ln -s /mnt/beegfs/userdata/j_wang/.conda/envs/pipeline_GATK_2.1.4_V2 your_conda_dir/envs/pipeline_GATK_2.1.4_V2
```

- Step 2. deploy workflow

Create a directory for your project, then create soft links to your datasets in the directory DNA_samples. Please make sure 
that the pattern of files name is {file_name}_[012].fastq.gz. Moreover, keep in mind that the softlinks should be always accessible on the work nodes.

```
$ mkdir -p /mnt/beegfs/scratch/${USER}/03_Results/
$ cd /mnt/beegfs/scratch/${USER}/03_results
$ mkdir -p projectname/analysis_name ; cd !$
$ ln -s /mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/workflow 
$ cp /mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/utils/start_pipeline.sh .
$ mkdir -p DNA_samples
$ ln -s /somewhere_datadir/*.fastq.gz DNA_samples 
```
- Step 3. configure workflow

1. If there are both tumor samples and normal samples, then you need create a file **variant_call_list_TvN.tsv** in the project directory. The first column is the name of tumor samples, and second column is for normal samples. Each row is a tumor vs normal pair. The seperator is tab. 

2. If there are both tumor samples and panel of normal samples, then you need create a file **variant_call_list_Tp.tsv** in the project directory.

3. If there are tumor, normal samples and panel of normal samples, then you need create a file **variant_call_list_TvNp.tsv** in the project directory.

4. If there are only tumor samples, then you need to create a file **variant_call_list_T.tsv** in the project directory.
   
5. If there are only normal samples, then you need to generate a file **variant_call_list_N.tsv** in the project directory.

Then, you need to modify the bash file start_pipeline.sh. For example, if you need to run WES pipeline for mice samples in tumor vs normal mode, then the options in the --config should modified as follow. If you don't set the values, then the default values will be taken. The default value of samples is human, and for seq_type is WGS, for mode is TvN 

```
$ cd /mnt/beegfs/scratch/username/yourprojectdir/projectname
$ mkdir -p config 
$ emacs -nw config/variant_call_list_TvN.tsv
$ cat config/variant_call_list_TvN.tsv
tumor_sample_A  normal_sample_A
tumor_sample_B  normal_sample_B
$ emacs -nw start_pipeline.sh
snakemake -c 'sbatch --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --rerun-incomplete --config samples=mouse seq_type=WES mode=TvN
```
- Step 4. run workflow
```
$ sbatch start_pipeline.sh
Submitted batch job {jobid}
$ cat slurm-{jobid}.out
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

![alt text](https://github.com/jinxin-wang/Genome_Sequencing_Analysis/blob/main/utils/images/pipeline.png)
