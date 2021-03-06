library(survival)
library(coin)
library(ggplot2)

source("~/Documents/Rscripts/FACSmarkerTCGA/140508_coexpressionFunctions.R")
source("~/Documents/Rscripts/multiplot.R")
############################################## IO and general munging #############################################
# Load the signature
verhaakSignature = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/survival/140530_liberalSignatureScores2SD.txt", row.names=1)

verhaakSignature = verhaakSignature[,c("CD133","CD44","GeneExp_Subtype","G_CIMP_STATUS", 'colours')]
clinical = read.delim("~/Documents/public-datasets/cancerBrowser/TCGA_GBM_exp_HiSeqV2-2014-05-02/clinical_dataDots.txt", row.names=1)

# Call the FACS subtype
verhaakSubtypeCall = callMarkerSubtype(verhaakSignature, 0, 0)

# Extract the clinical data for the RNAseq patients
matched = intersect(row.names(clinical), row.names(verhaakSubtypeCall))
# Subset clinical data for intersect
clin = clinical[matched, c("CDE_DxAge", "CDE_survival_time", "CDE_vital_status","X_EVENT", "gender", 'CDE_chemo_adjuvant_tmz', 'CDE_chemo_tmz',
                           'CDE_radiation_any', 'CDE_tmz_chemoradiation_standard', 'GeneExp_Subtype')]

############################################## bind the clinical and subtyping info together #############################################

boundData = merge.data.frame(clin, verhaakSubtypeCall, by.x="row.names", by.y="row.names")
boundData = sort.dataframe(boundData, "subtype")
row.names(boundData) = boundData$Row.names
boundData$subtype = as.factor(boundData$subtype)

# Fix up the GCIMP to only have true and false
boundData$G_CIMP_STATUS = as.character(boundData$G_CIMP_STATUS)
boundData$G_CIMP_STATUS[boundData$G_CIMP_STATUS %in% 'G-CIMP'] = 1
boundData$G_CIMP_STATUS[!boundData$G_CIMP_STATUS %in% 1] = 0
boundData$G_CIMP_STATUS = as.numeric(boundData$G_CIMP_STATUS)

boundData = boundData[!is.na(boundData$X_EVENT),]

############################################# Analysing the data for survival ##################################
data.surv = Surv(boundData$CDE_survival_time, event=boundData$X_EVENT)

xtabs(~ subtype, boundData)
sur.fit = survfit(data.surv ~ subtype, boundData)
par(mfrow=c(1,1))

plot(sur.fit, main='TCGA GBM cohort all patients classified by subtype',ylab='Survival probability',xlab='survival (days)', 
     col=c("red",'blue'),
     cex=1.75, conf.int=F, lwd=1.33, cex.axis=1.5, cex.lab=1.5)
legend('topright', c('CD133-M n=90', 'CD44-M n=75'), title="Coexpression subtype",
       col=c("red",'blue'),
       lwd=1.33, cex=1.75, bty='n', xjust=0.5, yjust=0.5)

coxPH = coxph(data.surv ~  subtype +  CDE_DxAge  + gender + G_CIMP_STATUS + CDE_chemo_tmz + CDE_radiation_any, 
              data=boundData, na.action="na.omit")
summary(coxPH)

data.surv = Surv(boundData$CDE_survival_time, event=boundData$X_EVENT)
coxPH = coxph(data.surv ~  subtype + G_CIMP_STATUS, 
              data=boundData, na.action="na.omit")
summary(coxPH)

# Plot survival curve including G-CIMP
boundData$threeGroup = boundData$subtype
levels(boundData$threeGroup) = c("CD133", "CD44", "G-CIMP")
boundData$threeGroup[boundData$G_CIMP_STATUS %in% 1] = as.factor("G-CIMP")
data.surv = Surv(boundData$CDE_survival_time, event=boundData$X_EVENT)
threeGroupFit = survfit(data.surv ~ threeGroup, boundData)

plot(threeGroupFit, main='RNAseq',ylab='Survival probability',xlab='survival (days)', 
     col=c("red",'blue', 'green'), cex.axis=1.33, cex.lab=1.33,
     cex=1.75, conf.int=F, lwd=1.33)
legend('topright', c('CD133', 'CD44', "G-CIMP"), title="",
       col=c("red",'blue', 'green'),
       lwd=1.33, cex=1.2, bty='n', xjust=0.5, yjust=0.5)

twoGroup = !boundData$threeGroup %in% 'G-CIMP'
test = surv_test(data.surv~as.factor(boundData$threeGroup), data=boundData, subset=twoGroup)
test
text(locator(1),labels='p-value 0.065 \nCD133 vs CD44', cex=1) #add the p-value to the graph

############################################# Investigate Classical and Neural survival ##################################
head(boundData)
classical = boundData[boundData$GeneExp_Subtype.x %in% 'Classical',]
neural = boundData[boundData$GeneExp_Subtype.x %in% 'Neural',]

neuralPlot = ggplot(data=classical, aes(x=subtype, y=CDE_survival_time, fill=subtype)) + geom_boxplot() + guides(fill=FALSE) +
            xlab("Subtype") + ylab("Survival") + # Set axis labels
            ggtitle("Survival of Classical GBMs\n by coexpression subtype") + theme_bw(base_size=20)

classPlot = ggplot(data=neural, aes(x=subtype, y=CDE_survival_time, fill=subtype)) + geom_boxplot() + guides(fill=FALSE) +
            xlab("Subtype") + ylab("Survival") + # Set axis labels
            ggtitle("Survival of Neural GBMs\n by coexpression subtype") + theme_bw(base_size=20)

multiplot(neuralPlot, classPlot, cols=2)

t.test(CDE_survival_time ~ subtype, data=classical)
t.test(CDE_survival_time ~ subtype, data=neural)