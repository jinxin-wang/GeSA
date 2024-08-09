#!/usr/bin/env Rscript

library("optparse")
 
option_list = list(
    make_option(c("-f", "--file"), type="character", default=NULL, 
              help="dataset file name", metavar="character"),
    make_option(c("-o", "--out"), type="character", default=NULL, 
              help="output file name [default= %default]", metavar="character")
); 
 
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

RData <- opt$file 
fileName <- opt$out

load(RData)
sname <- strsplit(RData, '_vs_')[[1]][1]
purity<- c(fit$purity)
ploidy<- c(fit$ploidy)

res <- data.frame(sname, purity, ploidy)

write.csv(x=res, file=fileName, row.names=FALSE, quote=FALSE)
