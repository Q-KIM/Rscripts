library(sqldf)
library(ggplot2)
library(plyr)

source("~/Documents/Rscripts/cellBiologyAnalysisFunctions.R")
source('~/Documents/Rscripts/140211_multiplotGgplot2.R')

setwd("~/Documents/Cell_biology/141023_summary/resazurin/")
list.files()

# Intialise and write into database
db <- dbConnect(SQLite(), dbname="assaySummary.sqlite")

# I am going to have to include the background controls if I want to compare across experiments
growth = read.delim("141111_resazurinSummary.txt")
# colnames(growth) = c("patient", "assayDate", "subpop", "rep1", "rep2", "rep3", "mean", "sd", "treatment")
growth$sample = paste(growth[,"patient"], growth[,"subpop"], sep="_")
growth$mean = rowMeans(growth[,c(4:6)], na.rm=T)
growth$sd = apply(growth[,c(4:6)], 1, sd, na.rm=T)
growth$cv = growth$sd / growth$mean * 100

write.table(growth, "141112_growthSummary.txt", sep='\t')
# I munged the data in excel and made the appropriate normalisations.
# The important columns are growth std and tmzstd
growthMung = read.delim("141112_growthNormaliseConfident.txt")
anova(lm(mean ~ patient + treatment + subpop, data = growthMung))

bw = c("grey21", "grey82", "grey52", "grey97")
color = c("chartreuse4", "skyblue2", "gold", "orangered1")

################## Growth assay ############################
#Plot the raw results
growthPlot = ggplot(growthMung[growthMung$treatment %in% 'DMSO',], 
                     aes(x=patient, y=growthStd, fill=subpop)) + 
    scale_fill_manual(values=color) +
    #scale_fill_manual(values=bw) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    #geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2, position=position_dodge(0.9)) +
    xlab("PDGC") + ylab("Fluorescent intensity") +
    ggtitle("Growth at day 7 by marker status") +  # Set title
    theme_bw(base_size=16) + theme(axis.text.x = element_text(angle = 90, hjust = 1), text = element_text(size=24))
growthPlot
################### Summarise by marker status and get sem ################### 
# extract Growth columns
growth = growthMung[growthMung$treatment %in% 'DMSO',]
growthSummary <- ddply(growth, 'subpop', summarise,
                N    = length(growthStd), mean = mean(growthStd),
                geoMean = exp(mean(log(growthStd))), geoSD = exp(sd(log(growthStd))),
                sd   = sd(growthStd), se   = sd / sqrt(N) )

growthSumPlot = ggplot(growthSummary, aes(x=subpop, y=mean, fill=subpop)) + 
    scale_fill_manual(values=color) + guides(fill=FALSE) +
    #scale_fill_manual(values=bw) +  guides(fill=FALSE) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    geom_errorbar(aes(ymin=mean-se, ymax=mean+se), width=.2, position=position_dodge(0.9)) +
    xlab("Subpopulation") + ylab("Growth relative to CD44-/CD133-") +
    ggtitle("Growth at day 7 by \nmarker status") +  # Set title
    theme_bw(base_size=18) + theme(axis.text.x = element_text(angle = 90, hjust = 1), text = element_text(size=24))
growthSumPlot

# pdf(file="./141118_growthDMSObw.pdf", useDingbats=F, height=12, width=18)
# growthSumPlot
# dev.off()

anova(lm(mean ~ subpop + patient, data = growth)) #  0.04828 *  
TukeyHSD(aov(mean ~ subpop, data = growth), which="subpop") # nothing significant is post hoc
write.table(growth, '141113_growthData.txt', sep='\t')

with(growth, pairwise.t.test(growthStd, subpop, 
    p.adj="fdr", paired=F))

################### TMZ analysis ################### 
tmz = growthMung[growthMung$treatment %in% 'TMZ',]
tmzSummary <- ddply(tmz, 'subpop', summarise,
                       N    = length(TMZstd), mean = mean(TMZstd),
                       geoMean = exp(mean(log(TMZstd))), geoSD = exp(sd(log(TMZstd))),
                       sd   = sd(TMZstd), se   = sd / sqrt(N) )

tmzSumPlot = ggplot(tmzSummary, aes(x=subpop, y=mean, fill=subpop)) + 
    scale_fill_manual(values=color) +  guides(fill=FALSE) +
    #scale_fill_manual(values=bw) +  guides(fill=FALSE) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    geom_errorbar(aes(ymin=mean-se, ymax=mean+se), width=.2, position=position_dodge(0.9)) +
    xlab("PDGC") + ylab("Temozolomide resistance") +
    ggtitle("Resistance to TMZ at day 7 \nby marker status") +  # Set title
    theme_bw(base_size=18) + theme(axis.text.x = element_text(angle = 45, hjust = 1), text = element_text(size=24))
tmzSumPlot

# pdf(file="./141112_growthTMZ.pdf", useDingbats=F, height=12, width=18)
# tmzSumPlot
# dev.off()

anova(lm(mean ~ subpop + patient, data = tmz)) # 0.04134 *  
TukeyHSD.aov(aov(mean ~ subpop + patient, data = tmz), which="subpop")
# CD44+/CD133--CD44-/CD133-  0.0480090
# CD44+/CD133+-CD44-/CD133-  0.9999899

write.table(tmz, '141113_tmzData.txt', sep='\t')

tmzPlot = ggplot(growthMung[growthMung$treatment %in% 'TMZ',], 
                    aes(x=patient, y=TMZstd, fill=subpop)) + 
    scale_fill_manual(values=color) +
    #scale_fill_manual(values=bw) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    #geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2, position=position_dodge(0.9)) +
    xlab("PDGC") + ylab("Growth relative to CD44-/CD133-") +
    ggtitle("Growth at day 7 by marker status") +  # Set title
    theme_bw(base_size=16) + theme(axis.text.x = element_text(angle = 90, hjust = 1), text = element_text(size=24))
tmzPlot

#### Write into database ####
dbWriteTable(conn = db, name = "growthData", value = growthData, row.names = TRUE)
dbWriteTable(conn = db, name = "tmzData", value = tmzData, row.names = TRUE)

dbDisconnect(db)