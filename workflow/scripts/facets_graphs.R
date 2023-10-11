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
rcmat = readSnpMatrix(datafile)
xx = preProcSample(rcmat)
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
