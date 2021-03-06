# Big qPCR expt
source('~/Documents/Rscripts/qPCRFunctions.R')
source('~/Documents/Rscripts/120612-multiplot.R')

setwd('~/Documents/RNAdata/qPCRexpt/140728_mixedPop/140805_honourMashup/')
# rawData = read.delim('140805_honoursMashup.txt', skip=1)
# map = '../140805_384map.txt'
# 
# # Convert the 384 well plate into the sample label
# plate = transposeLinear(map)
# plateMap = splitSampleName(plate)
# plateMap = plateMap[,c(1:4)]
# 
# data = buildDataFrameFromddCT(plateMap, rawData)
# Use the mixed order function to sort the dataframe by sample number
dataSorted = data[mixedorder(data$Name),]
#write.table(dataSorted, '140805_Cpvalues.txt', row.names=F, sep='\t')

dataMy = dataSorted[c(1:168),]
rm(data, dataSorted, plate, plateMap, rawData)

# Extract replicates
replicates = extractReplicates(c(1:168), dataMy)
data = replicates[[3]]

#write.table(data, '140808_replicatesDan.txt', sep='\t')

# START HERE
data = read.delim('output/140808_replicatesDanfixedNames.txt', row.names=1)
##################################### Some QC plots #####################################
plot(dataSorted$Cp, dataSorted$location, pch=16, col='pink', main='Raw Cp scores qRT-PCR expt with honours students')

# Plot correlation of the replicates
plot(data$Cp.x, data$Cp.y, main='Replicate accuracy Cp', ylab='Cp replicate 1', xlab='Cp replicate 2', pch=16)
abline(lm(data$Cp.x ~ data$Cp.y), col='red')
summary(lm(data$Cp.x ~ data$Cp.y))
# text(locator(1), labels='R squared = 0.975')
par(mfrow=c(1,1))

############################################ Calculate the ddCt scores #################################################
# Subset the data by cell line
clones = levels(data$origin.x)
c035 = data[data$origin.x %in% c("035_CD44-/CD133-", "035_CD44-/CD133+", "035_CD44+/CD133-", "035_CD44+/CD133+", "035_mixed"),]
c041 = data[data$origin.x %in% c("041_CD133neg","041_CD133pos","041_mixed"),]
mixed = data[data$origin.x %in% c("035_mixed", "039_mixed", "020_mixed", "041_mixed"),]

row.names(c035) = paste(c035$origin.x, c035$gene.x)
row.names(c041) = paste(c041$origin.x, c041$gene.x)
row.names(mixed) = paste(mixed$origin.x, mixed$gene.x)

# Change Cp values of 40 to NA
c035$meanCP[c035$meanCP == 40] = NA
c041$meanCP[c041$meanCP == 40] = NA
mixed$meanCP[mixed$meanCP == 40] = NA

# The ddCt
c035$ddCt = ddCTcalculate(geneOfInterest=c035$gene.x, sampleOfInterest=c035$origin.x,
                          houseKeepingGene='GAPDH', referenceSample='035_mixed', data=c035) 

c041$ddCt = ddCTcalculate(geneOfInterest=c041$gene.x, sampleOfInterest=c041$origin.x,
                          houseKeepingGene='GAPDH', referenceSample='041_mixed', data=c041)

mixed$ddCt = ddCTcalculate(geneOfInterest=mixed$gene.x, sampleOfInterest=mixed$origin.x,
                          houseKeepingGene='GAPDH', referenceSample='035_mixed', data=mixed)

# Bind the data together
bindDataMatched = rbind(c035, c041)
bindDataMatched = bindDataMatched[mixedorder(bindDataMatched$origin.x),]
write.table(bindDataMatched, './output/140808_ddCtValuesMatched.txt', sep='\t')
write.table(mixed, './output/140808_ddCtValuesMixed.txt', sep='\t')

######################################### Plot the ddCt values ########################################################

clone035 = ggplot(data=c035,
                  aes(x=gene.x, y=ddCt, fill=origin.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="Gene") +      # Set legend title
    #scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 0.5),0.5)) + # This modifies the scale of the y axis.
    xlab("Sample") + ylab("Gene expression normalised to mixed population") + # Set axis labels
    ggtitle("Expression of Proneural/ Mesenchymal markers for GPSC number #035") +  # Set title+
    theme_bw(base_size=18)
# clone035 + theme(axis.text.x = element_text(angle = 90, hjust = 1))

c041$ddCtN = ddCTcalculate(geneOfInterest=c041$gene.x, sampleOfInterest=c041$origin.x,
                          houseKeepingGene='GAPDH', referenceSample='041_CD133neg', data=c041)

clone041 = ggplot(data=c041, aes(x=gene.x, y=ddCtN, fill=origin.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="Gene") +      # Set legend title
    #scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 0.5),0.5)) + # This modifies the scale of the y axis.
    xlab("Gene") + ylab("Gene expression normalised to CD133-") + # Set axis labels
    ggtitle("Expression of Proneural/ Mesenchymal markers for GPSC number 041") +  # Set title
    theme_bw(base_size=18)
clone041 + theme(axis.text.x = element_text(angle = 90, hjust = 1))


mixedPop = ggplot(data=mixed[!mixed$origin.x %in% '035_mixed',], aes(x=gene.x, y=ddCt, fill=origin.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="Sample") +      # Set legend title
    #scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 0.5),0.5)) + # This modifies the scale of the y axis.
    xlab("Gene") + ylab("Gene expression normalised to GPSC #035") + # Set axis labels
    ggtitle("Gene expression normalised to CD44-/CD133- subpopulation") +  # Set title
    theme_bw(base_size=18)
mixedPop + theme(axis.text.x = element_text(angle = 90, hjust = 1))

############################################ Calculate the ddCt scores based on double Neg #################################################

# The ddCt
c035$ddCtDN = ddCTcalculate(geneOfInterest=c035$gene.x, sampleOfInterest=c035$origin.x,
                          houseKeepingGene='GAPDH', referenceSample='035_CD44-/CD133-', data=c035) 

clone035 = ggplot(data=c035,
                  aes(x=gene.x, y=ddCtDN, fill=origin.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="Subpopulation") +      # Set legend title
    #scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 0.5),0.5)) + # This modifies the scale of the y axis.
    xlab("Gene") + ylab("Gene expression normalised to CD44-/CD133- subpopulation") + # Set axis labels
    ggtitle("Expression of Proneural/ Mesenchymal markers for GPSC number #035") +  # Set title+
    theme_bw(base_size=18)
clone035 + theme(axis.text.x = element_text(angle = 90, hjust = 1))

multiplot(clone035 + theme(axis.text.x = element_text(angle = 90, hjust = 1)), clone041 + theme(axis.text.x = element_text(angle = 90, hjust = 1)), 
          mixedPop + theme(axis.text.x = element_text(angle = 90, hjust = 1)), cols=2)

############################################ subset the data based on useful stuff #################################################

c035Complete = c035[complete.cases(c035$ddCtDN),]
c041Complete = c041[complete.cases(c041$ddCtN),]
mixedComplete = mixed[complete.cases(mixed$ddCt),]

clone035 = ggplot(data=c035Complete,
                  aes(x=gene.x, y=ddCtDN, fill=origin.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="Subpopulation") +      # Set legend title
    #scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 0.5),0.5)) + # This modifies the scale of the y axis.
    xlab("Gene") + ylab("Gene expression normalised to CD44-/CD133- subpopulation") + # Set axis labels
    ggtitle("Expression of Proneural/ Mesenchymal markers for GPSC number #035") +  # Set title+
    theme_bw(base_size=18)
clone035 + theme(axis.text.x = element_text(angle = 90, hjust = 1))

clone041 = ggplot(data=c041Complete, aes(x=gene.x, y=ddCtN, fill=origin.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="Gene") +      # Set legend title
    #scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 0.5),0.5)) + # This modifies the scale of the y axis.
    xlab("Gene") + ylab("Gene expression normalised to CD133-") + # Set axis labels
    ggtitle("Expression of Proneural/ Mesenchymal markers for GPSC number 041") +  # Set title
    theme_bw(base_size=18)
clone041 + theme(axis.text.x = element_text(angle = 90, hjust = 1))

mixedPop = ggplot(data=mixedComplete[!mixedComplete$origin.x %in% '035_mixed',]
                  , aes(x=gene.x, y=ddCt, fill=origin.x)) + 
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    scale_fill_hue(name="Sample") +      # Set legend title
    #scale_y_continuous(breaks = round(seq(min(bindData$ddCt), max(bindData$ddCt), by = 0.5),0.5)) + # This modifies the scale of the y axis.
    xlab("Gene") + ylab("Gene expression normalised to GPSC #035") + # Set axis labels
    ggtitle("Gene expression normalised to CD44-/CD133- subpopulation") +  # Set title
    theme_bw(base_size=18)
mixedPop + theme(axis.text.x = element_text(angle = 90, hjust = 1))

mixedPop + theme(axis.text.x = element_text(angle = 90, hjust = 1))

multiplot(clone035 + theme(axis.text.x = element_text(angle = 90, hjust = 1)), clone041 + theme(axis.text.x = element_text(angle = 90, hjust = 1)), 
          mixedPop + theme(axis.text.x = element_text(angle = 90, hjust = 1)), cols=2)