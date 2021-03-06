library(sqldf)
library(ggplot2)

source("~/Documents/Rscripts/cellBiologyAnalysisFunctions.R")
source('~/Documents/Rscripts/140211_multiplotGgplot2.R')

setwd("~/Documents/Cell_biology/141023_summary/")
list.files()

# Intialise and write into database
db <- dbConnect(SQLite(), dbname="assaySummary.sqlite")

# I am going to have to include the background controls if I want to compare across experiments
growth = read.delim("141023_resazurinSummaryRoundEd.txt")
colnames(growth) = c("patient", "assayDate", "subpop", "rep1", "rep2", "rep3", "mean", "sd", "treatment")
growth$sample = paste(growth[,"patient"], growth[,"subpop"], sep="_")
    
# invasion = read.delim("141023_invasionSumRound.txt")
# elda = read.delim("141023_eldaSummary.txt")

bw = c("grey21", "grey82", "grey52", "grey97")
color = c("chartreuse4", "skyblue2", "gold", "orangered1")

################## Growth assay ############################
# Plot the raw results
growthPlot = ggplot(growth[growth$treatment %in% 'DMSO',], 
                     aes(x=patient, y=mean, fill=subpop)) + 
    scale_fill_manual(values=color) +
    #scale_fill_manual(values=bw) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2, position=position_dodge(0.9)) +
    xlab("PDGC") + ylab("Fluorescent intensity") +
    ggtitle("Growth at day 7 by \nmarker status") +  # Set title
    theme_bw(base_size=16) + theme(axis.text.x = element_text(angle = 90, hjust = 1), text = element_text(size=24))

four = calcGrowthNormalised(growth, "#004")
twenty = calcGrowthNormalised(growth, "#020")
twenty8 = calcGrowthNormalised(growth, "#028")
thirty5 = calcGrowthNormalised(growth, "#035")
thrity9 = calcGrowthNormalised(growth, "#039")
# 041 was done twice, need to separate
fourty1 = calcGrowthNormalised(growth[c(1:34),], "#041")
fourty2 = calcGrowthNormalised(growth[c(35:38),], "#041")
growthData = rbind(four, twenty, thirty5, thrity9, fourty1, fourty2)
rm(four, twenty, thirty5, thrity9, fourty1, fourty2)
# Get rid of the duplicate #041 readings
growthData = growthData[c(1:15,17),]

# Plot the normalised growth results
normalisedGrowthPlot = ggplot(growthData, aes(x=patient, y=normDN, fill=subpop)) + 
    scale_fill_manual(values=color) +
    #scale_fill_manual(values=bw) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    xlab("PDGC") + ylab("Cell number relative to\nCD44-/CD133-") +
    ggtitle("Growth at day 7 by \nmarker status") +  # Set title
    theme_bw(base_size=16) + theme(axis.text.x = element_text(angle = 90, hjust = 1), text = element_text(size=24))

# Summarise by marker status and get sem
summariseGrowth = summariseByFactor(growthData, "subpop", "treatment")
growthSummPlot = ggplot(summariseGrowth, aes(x=subpop, y=mean, fill=subpop)) + 
    scale_fill_manual(values=color) +
    #scale_fill_manual(values=bw) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    geom_errorbar(aes(ymin=mean-se, ymax=mean+se), width=.2, position=position_dodge(0.9)) +
    xlab("Subpopulation") + ylab("Cell number relative to\nCD44-/CD133-") +
    ggtitle("Growth at day 7 by \nmarker status") +  # Set title
    theme_bw(base_size=16) + theme(axis.text.x = element_text(angle = 45, hjust = 1), text = element_text(size=24))

multiplot(growthPlot, normalisedGrowthPlot, growthSummPlot, cols=2)

anova(lm(normDN ~ subpop, data = growthData))

################## TMZ assay ############################
calcDMSOcontrol = function(dataFrame) {
    vehicle = dataFrame[dataFrame$treatment %in% 'DMSO',]
    tmz = dataFrame[dataFrame$treatment %in% 'TMZ',]
    tmz$dmsoCorrected = tmz$mean / vehicle$mean
    return (tmz)
}
tmz = calcDMSOcontrol(growth)

four = calcTMZNormalised(tmz, "#004")
twenty = calcTMZNormalised(tmz, "#020")
twenty8 = calcTMZNormalised(tmz, "#028")
thirty5 = calcTMZNormalised(tmz, "#035")
thrity9 = calcTMZNormalised(tmz, "#039")
# 041 was done twice, need to separate
fourty1 = calcTMZNormalised(tmz[c(1:17),], "#041")
fourty2 = calcTMZNormalised(tmz[c(18:19),], "#041")
tmzData = rbind(four, twenty, thirty5, thrity9, fourty1, fourty2)
rm(four, twenty, thirty5, thrity9, fourty1, fourty2)
# Get rid of the duplicate #041 readings
tmzData = tmzData[c(1:15,17),]

normalisedTMZPlot = ggplot(tmzData, aes(x=patient, y=normDN, fill=subpop)) + 
    scale_fill_manual(values=color) +
    #scale_fill_manual(values=bw) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    xlab("PDGC") + ylab("Cell number relative to\nCD44-/CD133-") +
    ggtitle("TMZ sensitivity at day 7 by \nmarker status") +  # Set title
    theme_bw(base_size=16) + theme(axis.text.x = element_text(angle = 90, hjust = 1), text = element_text(size=24))

summariseTMZ = summariseByFactor(tmzData, "subpop", "treatment")
tmzSummPlot = ggplot(summariseTMZ, aes(x=subpop, y=mean, fill=subpop)) + 
    scale_fill_manual(values=color) +
    #scale_fill_manual(values=bw) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    geom_errorbar(aes(ymin=mean-se, ymax=mean+se), width=.2, position=position_dodge(0.9)) +
    xlab("Subpopulation") + ylab("Cell number relative to\nCD44-/CD133-") +
    ggtitle("TMZ sensitivity at day 7 by \nmarker status") +  # Set title
    theme_bw(base_size=16) + theme(axis.text.x = element_text(angle = 45, hjust = 1), text = element_text(size=24))

pdf(file="./141028_growthTMZ.pdf", useDingbats=F, height=12, width=18)
multiplot(growthPlot, growthSummPlot, normalisedTMZPlot, tmzSummPlot, cols=2)
dev.off()

anova(lm(normDN ~ subpop, data = tmzData))

#### Write into database ####
dbWriteTable(conn = db, name = "growthData", value = growthData, row.names = TRUE)
dbWriteTable(conn = db, name = "tmzData", value = tmzData, row.names = TRUE)

dbDisconnect(db)