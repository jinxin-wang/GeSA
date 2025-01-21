## Introduction
GeSA (**Ge**nome **S**equencing **A**nalysis Pipeline) is a workflow designed to detect variants in whole genome, whole exome, or targeted sequencing data, specifically for Human and Mouse samples. GeSA can handle various scenarios including tumor-only, tumor/(matched/unmatched) normal, tumor/Panel of Normal (PoN), or tumor/(matched/unmatched) normal/PoN, as well as cell line data.

GeSA was first prototyped by Ismael Padioleau, Denis Vorobyev and Leonardo Panunzi. [Jinxin WANG](https://github.com/jinxin-wang/) refactored the prototype scripts and continued development alongside his colleagues EAST Philip, Ivan Valiev and Andrey Yurchenko. Significant contributions have also been made by [Jomar SANGALANG](https://github.com/jsangalang), [Andrei Ivashkin](https://github.com/andrrrsss), [
Thibault DAYRIS](https://github.com/tdayris), [Yoann PRADAT](https://github.com/ypradat), and others.

## Summary

The pipeline consists of four modules that operate in a serial fashion. Each performs a specific task, reading from standard input files and producing standard output files (e.g., fastq, bam, vcf, maf). The pipeline's starting point and ending point can be dynamically set, providing great flexibility in analysis workflows. This modular design enables you to easily expand the pipeline with your own tools and analyses. 

## Contributions & Support

[Genomic Cancer Team](https://www.gustaveroussy.fr/en/genomics-non-melanoma-skin-cancer-team)

[Gustave Roussy Institute](https://www.gustaveroussy.fr/en/institute)

## Citations

