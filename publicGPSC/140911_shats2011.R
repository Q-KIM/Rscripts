library(limma)
library(affy)
library(gplots)
library(ggplot2)
source('~/Documents/Rscripts/120704-sortDataFrame.R')
source('~/Documents/Rscripts/multiplot.R')

##################### Build the genelist ###########################

library(annotate)
library(hgu133a2.db)
geneIDs = ls(hgu133a2ENTREZID)

#get gene ID numbers from the annptation package allowing for multiple probes to match mulitple genes
geneSymbols <- as.character(unlist(lapply(mget(geneIDs,env=hgu133a2SYMBOL),
                                          function (symbol) { return(paste(symbol,collapse="; ")) } )))
geneNames <- as.character(unlist(lapply(mget(geneIDs,env=hgu133a2GENENAME),
                                        function (name) { return(paste(name,collapse="; ")) } )))
unigene <- as.character(unlist(lapply(mget(geneIDs,env=hgu133a2UNIGENE),
                                      function (unigeneID) { return(paste(unigeneID,collapse="; ")) } )))

#strip the Hs from the start of unigene reference
unigene <- gsub("Hs\\.","",unigene)

#read the gene annotations into a dataframe for use in the topTable function of limma
genelist <- data.frame(GeneID=geneIDs,GeneSymbol=geneSymbols,GeneName=geneNames)
rm(geneSymbols, geneNames, unigene)

##################### IO ###########################
setwd('~/Documents/public-datasets/GPSC_subgroups/shats2010/GSE24716_RAW/')
list.files()

rawData = ReadAffy()
dm = readTargets('../designMatrix.txt')
myPalette <- colorRampPalette(c("blue", "white", "red"))(n = 1000)

par(mfrow=(c(2,1)))
# boxData = exprs(rawData)
#colnames(boxData) = dm$cellLine
boxplot(rawData, col=rainbow(21), main='Shats unNormalised data', las=1, mar=c(5,5,5,2))
data = rma(rawData, verbose=T)
norm = exprs(data)
colnames(norm) = dm$cellLine
boxplot(norm, col=rainbow(21), main='Shats normalised data', las=2, mar=c(5,5,5,2))
par(mfrow=(c(1,1)))
##################### Render the prinical components ###########################

dm$patient = as.factor(dm$patient)
pca = princomp(norm)
pcaDf = as.data.frame(cbind(pca$loadings[,1], pca$loadings[,2]))
pcaDf = cbind(pcaDf, dm)
dd_text = dm$subpopulation

g = ggplot(data=pcaDf, aes(x=V1, y=V2, color=subpopulation)) + 
    geom_point(shape=19) + #geom_smooth(method=lm, colour='red') +
    xlab("PC1") + ylab("PC2") + # Set axis labels
    ggtitle("Principal component analysis Shats 2011") +  # Set title
    theme_bw(base_size=18)
g
g2 = ggplot(data=pcaDf, aes(x=V1, y=V2, color=patient)) + 
    geom_point(shape=19) + #geom_smooth(method=lm, colour='red') +
    xlab("PC1") + ylab("PC2") + # Set axis labels
    ggtitle("Principal component analysis Shats 2011") +  # Set title
    theme_bw(base_size=18)
g2
g3 = ggplot(data=pcaDf, aes(x=V1, y=V2, color=growth)) + 
    geom_point(shape=19) + #geom_smooth(method=lm, colour='red') +
    xlab("PC1") + ylab("PC2") + # Set axis labels
    ggtitle("Principal component analysis Shats 2011") +  # Set title
    theme_bw(base_size=18)
g3
multiplot(g, g2,g3, cols=2)

##################### Make a heatmap ###########################
dm$colour = "black"
dm$colour[dm$subpopulation %in% 'CD133+'] = 'blue'
dm$colour[dm$subpopulation %in% 'CD133-'] = 'red'
dm$colour = as.factor(dm$colour)
name = paste(dm$patient, dm$growth, dm$subpopulation)

# Extract median absolute deviation and take the top 500
madData = apply(norm, 1, mad)

madDataSort = as.data.frame(madData)
madDataSort$probe = row.names(madDataSort)
colnames(madDataSort) = c('value', 'probe')
madDataSort = sort.dataframe(madDataSort, 1, highFirst=T)
top500 = row.names(madDataSort[c(1:500),])
topNorm = norm[top500,]
topNorm = sort.dataframe(topNorm, 1, highFirst=T)
name = paste(dm$patient, dm$subpopulation)

heatmap.2(topNorm, cexRow=0.8, main="Gene expression profiles CD133 sorted GPSCs", scale="row",
          Colv=as.factor(dm$subpopulation), keysize=1, trace="none", col=myPalette, density.info="none", dendrogram="row", 
          ColSideColors=as.character(dm$colour), labRow=NA,labCol=name, 
          offsetRow=c(1,1), margins=c(15,4))

heatmap.2(topNorm, cexRow=0.8, main="Gene expression profiles CD133 sorted GPSCs", scale="row",
          keysize=1, trace="none", col=myPalette, density.info="none", dendrogram="both", 
          ColSideColors=as.character(dm$colour), labRow=NA, labCol=name, 
          offsetRow=c(1,1), margins=c(15,4))

# Tkae the probe averages
summariseData = avereps(data, ID=genelist$GeneSymbol)
# Remove NAs
summariseData = summariseData[row.names(summariseData) != 'NA' ,]

##################### Export data ###########################
write.table(norm, '../analysis/140911_rmaNormalised.txt', sep='\t')
write.table(summariseData, '../analysis/140911_shatGEM.txt', sep='\t')
write.table(topNorm, '../analysis/140911_top500.txt', sep='\t')