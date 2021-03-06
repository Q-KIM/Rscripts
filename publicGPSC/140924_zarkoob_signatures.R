library(GSVA)
library(gplots)

##################### IO ###########################
setwd('~/Documents/public-datasets/GPSC_subgroups/zarkoob2013/analysis/')

data = read.delim('140923_zarookGEM.txt', row.names=1)
dataM = as.matrix(data)
dm = read.delim('../designMatrix.txt')
# Just the untreated controls

cd133Sig = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/140527_cd133Cutoff.txt", row.names=1)
cd44Sig = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/140527_cd44Cutoff.txt", row.names=1)
cd15 = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/CD15/140528_cd15Cutoff.txt", row.names=1)
aldh1 = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/ALDH1/140528_ALDH1Cutoff.txt", row.names=1)
itag6 = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/ITGA6//140528_ITGA6Cutoff.txt", row.names=1)
l1cam = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/L1CAM/140528_L1CAMCutoff.txt", row.names=1)

bigSigs = list("CD133" = row.names(cd133Sig), "CD44" = row.names(cd44Sig), "CD15" = row.names(cd15),
               "ALDH1"=row.names(aldh1), "ITGA6"=row.names(itag6), "L1CAM"=row.names(l1cam))
rm(cd133Sig, cd44Sig, cd15, aldh1, itag6, l1cam)

##################### GSVA ###########################
# dataM[is.na(dataM)] <- 0
bigResult = gsva(dataM, bigSigs,  rnaseq=F, verbose=T, parallel.sz=1)
bigResult = t(bigResult$es.obs)

dm$colour = c("blue", "red", "blue", "red", "blue", "red", "blue", "red")
dm$colour = as.factor(dm$colour)
myPalette <- colorRampPalette(c("blue", "white", "red"))(n = 1000)
name = paste(dm$source, dm$tissue, dm$subpopulation)

bigResult = bigResult[c(1:4),]
##################### heatMaps ###########################
pdf('../plots/140924_bigHeatMap.pdf', width=11.69, height=8.27, useDingbats=FALSE)
heatmap.2(t(bigResult), cexRow=1.5, cexCol=1.25, main="Enrichment of FACS marker signatures \n in FACS sorted GPSCs", scale="none",
          Rowv=NULL, Colv=TRUE, keysize=1, trace="none", col=myPalette, density.info="none", dendrogram="column",
          ColSideColors=as.character(dm$colour[1:4]), labCol=name, labRow=colnames(bigResult), 
          offsetRow=c(1,1), margins=c(14,7))
dev.off()

# heatmap.2(t(bigResult), cexRow=1.2, main="Enrichment of FACS marker signatures \n in FACS sorted GPSCs", scale="none",
#           Rowv=T, Colv=as.character(dm$colour), keysize=1, trace="none", col=myPalette, density.info="none", dendrogram="row", 
#           ColSideColors=as.character(dm$colour), labCol=name, labRow=colnames(bigResult), 
#           offsetRow=c(1,1), margins=c(14,7))

smallResult = bigResult[,c(1:3)]
# heatmap.2(t(smallResult), cexRow=1.2, main="Enrichment of FACS marker signatures \n in FACS sorted GPSCs", scale="none",
#           Rowv=T, Colv=as.character(dm$colour), keysize=1, trace="none", col=myPalette, density.info="none", dendrogram="row", 
#           ColSideColors=as.character(dm$colour), labCol=name, labRow=colnames(smallResult), 
#           offsetRow=c(1,1), margins=c(14,7))

pdf('../plots/140924_smallHeatMap.pdf', width=11.69, height=8.27, useDingbats=FALSE)
heatmap.2(t(smallResult), cexRow=1.5, cexCol=1.25,scale="none", #main="Enrichment of FACS marker signatures \n in FACS sorted GPSCs",
          Rowv=NULL, Colv=T, keysize=1, trace="none", col=myPalette, density.info="none", dendrogram="column", 
          ColSideColors=as.character(dm$colour[1:4]), labCol=name, labRow=colnames(smallResult), 
          offsetRow=c(1,1), margins=c(14,7))
dev.off()

# Do single genes
markers = as.matrix(data[c('CD44', 'FUT4', 'PROM1'),])

pdf('../plots/140924_mRNAHeatMap.pdf', width=11.69, height=8.27, useDingbats=FALSE)
heatmap.2(markers, cexRow=1.2, main="Enrichment of FACS marker mRNAs \n in FACS sorted GPSCs", scale="row",
          Rowv=T, Colv=as.character(dm$colour), keysize=1, trace="none", col=myPalette, density.info="none", dendrogram="row", 
          ColSideColors=as.character(dm$colour),  labCol=name, labRow=c('CD44', 'CD15', 'CD133'), 
          offsetRow=c(1,1), margins=c(14,7))
dev.off()