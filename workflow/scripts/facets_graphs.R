#!/usr/bin/env Rscript
library(facets)
args = commandArgs(trailingOnly=TRUE)

## Just because png call X11, and it is not available, this commande solve the problem
options(bitmapType='cairo')

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
    stop("At least one argument must be supplied (input file).n", call.=FALSE)
}

datafile = args[1]

#rcmat = readSnpMatrix(datafile)
#xx = preProcSample(rcmat)


if (facet_unmutch_normal) {
    rcmat = readSnpMatrix(datafile)
    xx = preProcSample(rcmat, ndepth=5,  het.thresh=0.10, unmatched=TRUE)
} else if (facet_cell_lines) {
    ###Facets modification for cell lines

    rcmat = readSnpMatrix(datafile)
    rcmat[,c(3:6)]=rcmat[,c(3:6)]*3
    xx = preProcSample(rcmat,snp.nbhd=5000,cval=500,ndepth=20,ndepthmax=5000,het.thresh=0.3,unmatched=T,gbuild="hg19", hetscale=T)
    oo=procSample(xx,cval=5000,min.nhet=30)
    fit=emcncf(oo,min.nhet = 30,trace = TRUE, unif=FALSE)
    
} else {
    rcmat = readSnpMatrix(datafile)
    xx = preProcSample(rcmat)
}


# oo=procSample(xx,cval=100)
# fit=emcncf(oo)

# save(oo,fit, xx, file = gsub('.csv.gz','_cval100.RData',datafile))
# write.table(fit$cncf, file=gsub('.csv.gz','_cval100_fitTable.tsv',datafile), quote = FALSE, row.names = FALSE, col.names = TRUE, sep="\t")

# png(filename=gsub('.csv.gz','_profile_cval100.png',datafile), width = 3840, height = 2160, units = "px", pointsize = 12, res = 288)
# plotSample(x=oo,emfit=fit)
# dev.off()

# png(filename=gsub('.csv.gz','_diagnostic_cval100.png',datafile), width = 3840, height = 2160, units = "px", pointsize = 12, res = 288)
# logRlogORspider(oo$out, oo$dipLogR)
# dev.off()

# pdf(gsub('.csv.gz','_cval100.pdf',datafile), width=10, pointsize=8 )
# plotSample(x=oo,emfit=fit)
# logRlogORspider(oo$out, oo$dipLogR)
# dev.off()


## cval 300
# oo=procSample(xx,cval=300)
# fit=emcncf(oo)

# save(oo,fit, xx, file = gsub('.csv.gz','_cval300.RData',datafile))
# write.table(fit$cncf, file=gsub('.csv.gz','_cval300_fitTable.tsv',datafile), quote = FALSE, row.names = FALSE, col.names = TRUE, sep="\t")

# png(filename=gsub('.csv.gz','_profile_cval300.png',datafile), width = 3840, height = 2160, units = "px", pointsize = 12, res = 288)
# plotSample(x=oo,emfit=fit)
# dev.off()

# png(filename=gsub('.csv.gz','_diagnostic_cval300.png',datafile), width = 3840, height = 2160, units = "px", pointsize = 12, res = 288)
# logRlogORspider(oo$out, oo$dipLogR)
# dev.off()

# pdf(gsub('.csv.gz','_cval300.pdf',datafile), width=10, pointsize=8 )
# plotSample(x=oo,emfit=fit)
# logRlogORspider(oo$out, oo$dipLogR)
# dev.off()

## cval 500
oo=procSample(xx,cval=500)
fit=emcncf(oo)

save(oo,fit, xx, file = gsub('.csv.gz','_cval500.RData',datafile))
write.table(fit$cncf, file=gsub('.csv.gz','_cval500_fitTable.tsv',datafile), quote = FALSE, row.names = FALSE, col.names = TRUE, sep="\t")

png(filename=gsub('.csv.gz','_profile_cval500.png',datafile), width = 3840, height = 2160, units = "px", pointsize = 12, res = 288)
plotSample(x=oo,emfit=fit)
dev.off()

png(filename=gsub('.csv.gz','_diagnostic_cval500.png',datafile), width = 3840, height = 2160, units = "px", pointsize = 12, res = 288)
logRlogORspider(oo$out, oo$dipLogR)
dev.off()

pdf(gsub('.csv.gz','_cval500.pdf',datafile), width=10, pointsize=8 )
plotSample(x=oo,emfit=fit)
logRlogORspider(oo$out, oo$dipLogR)
dev.off()
