source('~/Documents/Rscripts/140211_multiplotGgplot2.R')
source('~/Documents/Rscripts/qPCRFunctions.R')
setwd('~/Documents/RNAdata/qPCRexpt/140331_cd133s/')

library

subsetClones = function(cloneName) {
    # Takes the name of the clone as a string
    neg = paste(cloneName, '_neg', sep='')
    pos = paste(cloneName, '_pos', sep='')
    result = rawData[rawData$origin.x %in% c(neg, pos),]
    return (result)
}

########################################## IO #######################################################

# Convert the 384 well plate into the sample label
# Read in qPCR data. Stupid python script has too many dependies and the files are everywhere
filename = '384well_plateMap.txt'
# Convert the 384 well plate into the sample label
# Read in qPCR data
plate = transposeLinear(filename)
# Check the 384 well plate plain text file using cat or less. Gremlins in the file like empty wells and newlines will screw up the script

# Split the transposed file into source and gene
plateMap = splitSampleName(plate)

cp = read.delim('140403_cpScores.txt', skip=1)
tm = read.delim('140403_melt.txt', skip=1)

######################################### Filter and prepare data #####################################
data = buildDataFrameFromddCT(plateMap, cp)

# Return a datframe with the replicate data alongside
replicates = extractReplicates(c(1:384), data)
rawData = replicates[[3]]
row.names(rawData) = rawData$sample
write.table(rawData, '140403_rawData.txt', sep='\t')

# Extract replictes from the data set
rep1 = replicates[[1]]
rep2 = replicates[[2]]

# Set some graphs
par(las=2, mfrow=c(2,1))
par(las=2)
hist(data$Cp, main='Raw Cp values GIC cells', col='orange')

# Plot correlation of the replicates
plot(rawData$Cp.x, rawData$Cp.y, main='Replicate accuracy Cp', ylab='Cp replicate 1', xlab='Cp replicate 2', pch=16)
abline(lm(rawData$Cp.x ~ rawData$Cp.y), col='red')
summary(lm(rawData$Cp.x ~ rawData$Cp.y))
text(locator(1), labels='R squared = 0.9765')
par(mfrow=c(1,1))

############################################ Calculate the ddCt scores #################################################
# Subset the data by cell line
c011 = subsetClones('011')
c020 = subsetClones('020')
c041 = subsetClones('041')
c035 = subsetClones('035')
c030a = subsetClones('030a')
c020 = subsetClones('020')
c030 = subsetClones('030')

# The ddCt
c011$ddCt = ddCTcalculate(geneOfInterest=c011$gene.x, sampleOfInterest=c011$origin.x,
                                       houseKeepingGene='GAPDH', referenceSample='011_neg', data=c011)

c020$ddCt = ddCTcalculate(geneOfInterest=c020$gene.x, sampleOfInterest=c020$origin.x,
                     houseKeepingGene='GAPDH', referenceSample='020_neg', data=c020)

c030$ddCt = ddCTcalculate(geneOfInterest=c030$gene.x, sampleOfInterest=c030$origin.x,
                          houseKeepingGene='GAPDH', referenceSample='030_neg', data=c030)

c030a$ddCt = ddCTcalculate(geneOfInterest=c030a$gene.x, sampleOfInterest=c030a$origin.x,
                           houseKeepingGene='GAPDH', referenceSample='030a_neg', data=c030a)

c035$ddCt = ddCTcalculate(geneOfInterest=c035$gene.x, sampleOfInterest=c035$origin.x,
                          houseKeepingGene='GAPDH', referenceSample='035_neg', data=c035)

c041$ddCt = ddCTcalculate(geneOfInterest=c041$gene.x, sampleOfInterest=c041$origin.x,
                          houseKeepingGene='GAPDH', referenceSample='041_neg', data=c041)

# Bind the data together
bindData = rbind(c011, c030a, c035, c041, c020, c030)
write.table(bindData, '140403_ddCtValues.txt', sep='\t')
######################################### Plot the ddCt values ########################################################
positives = c('011_pos', '020_pos', '030_pos', '020_pos', '030a_pos', '035_pos', '041_pos')

allPlots = ggplot(data=bindData[bindData$origin.x %in% positives,], 
             aes(x=origin.x, y=ddCt, fill=gene.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="Gene") +      # Set legend title
    coord_cartesian(ylim = c(0, 10)) +
    scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 1),1)) + # This modifies the scale of the y axis.
    xlab("Sample") + ylab("Gene expression normalised to CD133") + # Set axis labels
    ggtitle("Comapring CD133 status") +  # Set title
    theme_bw(base_size=18)
#pdf('140403_ddCtBySample.pdf', paper='a4')
allPlots + theme(axis.text.x = element_text(angle = 90, hjust = 1))
#dev.off()

otherPlot = ggplot(data=bindData[bindData$origin.x %in% positives,], 
                  aes(x=gene.x, y=ddCt, fill=origin.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="sample") +      # Set legend title
    coord_cartesian(ylim = c(0, 7.5)) +
    scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 1),1)) + # This modifies the scale of the y axis.
    xlab("Sample") + ylab("Gene expression normalised to CD133") + # Set axis labels
    ggtitle("Comapring CD133 status") +  # Set title
    theme_bw(base_size=20)
#pdf('140403_ddCtBySample.pdf', paper='a4')
otherPlot + theme(axis.text.x = element_text(angle = 90, hjust = 1))
#dev.off()

multiplot(allPlots + theme(axis.text.x = element_text(angle = 90, hjust = 1)), otherPlot+ theme(axis.text.x = element_text(angle = 90, hjust = 1)))

posPlot = ggplot(data=bindData[bindData$origin.x %in% positives,], 
                 aes(x=gene.x, y=ddCt, fill=origin.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="sample") +      # Set legend title
    coord_cartesian(ylim = c(0, 7.5)) + # This sets the y axis limits
    scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 1),1)) + # This modifies the scale of the y axis.
    xlab("Sample") + ylab("Gene expression normalised to CD133 negative") + # Set axis labels
    ggtitle("Comapring CD133 status") +  # Set title
    theme_bw(base_size=20)
#pdf('140403_ddCtSamplePositives.pdf', paper='a4')
posPlot + theme(axis.text.x = element_text(angle = 90, hjust = 1))
#dev.off()

############################################ Construct the mean of the data #################################################
cd133 = build_ddCTmatrix('140403_ddCtValues.txt')
# Ran this on the command line but got only 1 column of data althoguh the headers appeared to have worked