#!/bin/bash

module load java

#### samples: [human|mouse], default: human
#### type_seq: [WGS|WES], default: WGS
#### mode: [TvN|TvNp|Tp|T], default: TvN

SAMPLES="human"
SEQ_TYPE="WGS"
MODE="TvN"

VAR_TABLE="variant_call_list_${MODE}.tsv"

if ( [ -d DNA_samples ] || [ -d bam ] ) && [ -f ${VAR_TABLE} ] && [ -d workflow ] ; then
    echo "Starting pipeline" ; 
    /mnt/beegfs/userdata/j_wang/.conda/envs/snakemake/bin/snakemake --cluster 'sbatch --output=logs/slurm/slurm.%j.%N.out --cpus-per-task={threads} --mem={resources.mem_mb}M -p {params.queue}' --jobs 20 --latency-wait 50 --rerun-incomplete --config samples=${SAMPLES} seq_type=${SEQ_TYPE} mode=${MODE} ;

else
    echo "init workspace"
fi 

if [ ! -d DNA_samples ] ; then
    echo "init DNA_samples directory" ; 
    mkdir -p DNA_samples ;
fi

if [ ! -d bam ] ; then
    echo "init bam files directory" ; 
    mkdir -p bam ;
fi 

if [ ! -f ${VAR_TABLE} ] ; then
    echo "init variant call table" ;
    touch ${VAR_TABLE} ;
fi

if [ ! -d workflow ] ; then
    echo "init softlink to main branch of pipeline" ; 
    ln -s /home/j_wang@intra.igr.fr/Genome_Sequencing_Analysis/workflow . ;
fi

