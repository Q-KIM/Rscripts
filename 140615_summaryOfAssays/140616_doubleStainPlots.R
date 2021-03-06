setwd('~/Documents/Cell_biology/proliferation/Resazurin/140614_summary')
source('~/Documents/Rscripts/140211_multiplotGgplot2.R')

calcDMSOcontrol = function(dataFrame) {
    vehicle = dataFrame[dataFrame$treatment %in% 'DMSO',]
    tmz = dataFrame[dataFrame$treatment %in% 'TMZ',]  
    tmz$rep1 = tmz$rep1 / vehicle$rep1
    tmz$rep2 = tmz$rep2 / vehicle$rep2
    tmz$rep3 = tmz$rep3 / vehicle$rep3
    tmz$mean = rowMeans(tmz[,c(4:6)], na.rm=T)
    tmz$sd = apply(tmz[,c(4:6)], 1, sd, na.rm=T)
    return (tmz)
}

calcProlifNormalised = function(dataFrame) {
    negative = dataFrame[dataFrame$cd133 %in% 'CD133_neg',]
    positive = dataFrame[dataFrame$cd133 %in% 'CD133_pos',]
    positive$rep1 = positive$rep1 / negative$rep1
    positive$rep2 = positive$rep2 / negative$rep2
    positive$rep3 = positive$rep3 / negative$rep3
    positive$mean = rowMeans(positive[,c(4:6)], na.rm=T)
    positive$sd = apply(positive[,c(4:6)], 1, sd, na.rm=T)
    return (positive)
}

extractPosNegReplicates = function(dataFrame) {
    neg = dataFrame[dataFrame$cd133 %in% 'neg',c(1,2,3,9)]
    pos = dataFrame[dataFrame$cd133 %in% 'pos',c(1,2,3,9)]
    negMean = mean(neg$dmsoCorrected)
    negSD = sd(neg$dmsoCorrected)
    posMean = mean(pos$dmsoCorrected)
    posSD = sd(pos$dmsoCorrected)
    negSummary = c(negMean, negSD)
    posSummary = c(posMean, posSD)
    result = rbind(negSummary, posSummary)
    result = as.data.frame(result)
    origin = c('negative', 'positive')
    result = cbind(origin, result)
    colnames(result) = c('origin', 'mean', 'sd')
    return (result)
}

normaliseCD133 <- function (dataFrame) {
    cd133Neg = dataFrame[dataFrame$cd133status %in% 'CD133_neg',]
    cd133Pos = dataFrame[dataFrame$cd133status %in% 'CD133_pos',]
    cd133NegAv = mean(cd133Neg$mean)
    cd133NegSd = sd(cd133Neg$mean) / sqrt(length(cd133Neg$mean))
    cd133PosAv = mean(cd133Pos$mean)
    cd133PosSd = sd(cd133Pos$mean) / sqrt(length(cd133Pos$mean))
    cd133 = as.data.frame(rbind(c(cd133NegAv, cd133NegSd), c(cd133PosAv, cd133PosSd)))
    cd133$cd133 = c('negative', 'positive')
    return (cd133)
}

################################ IO and subsetting ############################################

data = read.delim('140614_day7meanSD.txt')

# Subset for double stain
dataDoubleStain = data[!data$cd133status %in% c("CD133_neg", "CD133_pos"),]
dataDoubleStain = dataDoubleStain[dataDoubleStain$clone %in% "020",]


growthPlot7 = ggplot(data=dataDoubleStain[dataDoubleStain$treatment %in% 'DMSO',], 
                     aes(x=clone, y=mean, fill=cd133status)) + 
    #scale_fill_manual(values=c("darkorange", "royalblue")) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2, position=position_dodge(0.9)) +
    xlab("Clone") + ylab("Fluorescent intensity") +
    ggtitle("Proliferation at day 7 \nby CD44 and CD133 status") +  # Set title
    theme_bw(base_size=16) + theme(axis.text.x = element_text(angle = 90, hjust = 1))

day7TMZ = calcDMSOcontrol(dataDoubleStain)

tmzPlot7 = ggplot(data=day7TMZ, aes(x=clone, y=mean, fill=cd133status)) + 
    #scale_fill_manual(values=c("blue", "yellow")) +
    geom_bar(stat="identity", position=position_dodge(), colour="black") + 
    geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2, position=position_dodge(0.9)) +
    xlab("Clone") + ylab("Cell number relative to DMSO control") +
    ggtitle("Comparing temozolomide sensitivty at day 7 \nby CD44 and CD133 status") +  # Set title
    theme_bw(base_size=16) + theme(axis.text.x = element_text(angle = 90, hjust = 1))