library(edgeR)
setwd('~/Documents/RNAdata/danBatch1/bowtieGem/revHTSeq/')
source('~/Documents/Rscripts/annotateEnsembIDs.R')
source('~/Documents/Rscripts/120704-sortDataFrame.R')
files = list.files(pattern='*.txt')

f = lapply(files, read.delim, header=FALSE)
df1 = cbind(f[[1]],f[[2]],f[[3]],f[[4]],f[[5]],f[[6]])
df = df1[,c(2,4,6,8,10,12)]
row.names(df) = df1[,1]
colnames(df) = c('GIC_011', 'GIC_020', 'GIC_034', 'GIC_035', 'GIC_039', 'GIC_041')
labels = c('#011', '#020', '#034', '#035', '#039', '#041')

noFeatures = tail(df)
noCount = rownames(df) %in% c("no_feature","ambiguous","too_low_aQual",
                                "not_aligned","alignment_not_unique")
df = df[!noCount,]
totalCount = colSums(df)

#Build EdgeR objects
condition = c('long', 'long', 'long', 'short', 'short', 'short')
counts = DGEList(counts=df, group=condition)

# I remove genes with less than 0.5 cpm in 3 samples. For a library size of 20M this is 10 reads.
cpms = cpm(counts)
keep = rowSums(cpms >0.5) >=3
counts = counts[keep,]

#nomalise, plot MDS
d = calcNormFactors(counts)
plotMDS(d, labels=labels, col = c("darkgreen","blue")[factor(condition)], cex=1.25, main='MDS plot GIC RNA-seq batch1')

# Maximizes the negative binomial conditional common likelihood to give the estimate of the common dispersion across all tags.
#d = estimateCommonDisp(d)
# Compute an empirical Bayes estimate of the negative binomial dispersion parameter for each tag or transcript, 
d = estimateTagwiseDisp(d)

# Plot the dispersions. Tagwise vars is blue scatter. NB line is blue. Poisson line is black. Raw variance is maroon
plotMeanVar(d, show.tagwise.vars=TRUE, NBline=TRUE, main='Fitted dispersion GIC RNA-seq batch1')
legend('topleft', legend=c('Poisson line', 'Neg Binomial line', 'Tagwise disp', 'Raw disp'), fill=c('black', 'steelblue', 'skyblue', 'maroon'), cex=0.8)

plotBCV(d, 'Biological variation GIC RNA-seq batch1')

# Differential expression testing
de = exactTest(d, pair=c("long","short"))
tt = topTags(de, n=nrow(d))
head(tt$table)

# Create a graphical summary, such as an M (log-fold change) versus A (log-average expression) plot
rn = rownames(tt$table)
deg = rn[tt$table$FDR < .05]
plotSmear(d, de.tags=deg, main='MA plot GIC RNA-seq batch1')

result = ensembl_2_geneName(tt$table)
result = sort.dataframe(result, 7, highFirst=FALSE)
cutoff = result[result$FDR < 0.05,]
write.table(result, './vanillaEdgeR/131021_short_vs_long.txt', sep='\t')
write.table(cutoff, './vanillaEdgeR/131021_short_vs_longDEgenes.txt', sep='\t')