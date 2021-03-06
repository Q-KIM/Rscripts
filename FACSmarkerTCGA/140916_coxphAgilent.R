library(survival)
library(coin)
library(ggplot2)
library(sqldf)

source("~/Documents/Rscripts/FACSmarkerTCGA/140508_coexpressionFunctions.R")
source("~/Documents/Rscripts/multiplot.R")

removeEmptyField<- function (dataFrame, columnName) {
  # Remove entries with empty or NA values from dataFrame
  # Column name is a character string
  dataFrame = dataFrame[!is.na(dataFrame[,columnName]),]
  dataFrame = dataFrame[!(dataFrame[,columnName] %in% ""),]
  return (dataFrame)
}

############################ IO ################################
db = dbConnect(SQLite(), dbname="~/Documents/public-datasets/cancerBrowser/tcgaData.sqlite")
dbListTables(db)
clinical = dbReadTable(db, "clinicalAllPatients", row.names=1)
clinical = clinical[!is.na(clinical$X_EVENT),]
row.names(clinical) = clinical$Row_names__1
clinical = removeEmptyField(clinical, "G_CIMP_STATUS")

markerAgilent = dbReadTable(db, "markerScoresAgilent", row.names=1)
row.names(markerAgilent) = gsub("_", ".", row.names(markerAgilent))
molSubtype = c("blue", "red", "green", "purple")

# Extract the clinical data for the Agilent patients
matched = intersect(row.names(clinical), row.names(markerAgilent))
# Subset clinical data for intersect

#################### Do Agilent coxph ###################
clinAgilent = clinical[matched,]
data.surv = Surv(clinAgilent$CDE_survival_time, event=clinAgilent$X_EVENT)
coxPH = coxph(data.surv ~  subtype + CDE_DxAge  + gender + G_CIMP_STATUS + CDE_chemo_tmz + CDE_radiation_any, 
              data=clinAgilent, na.action="na.omit")
summary(coxPH)

# Plot survival curve including G-CIMP
clinAgilent$threeGroup = clinAgilent$subtype
levels(clinAgilent$threeGroup) = c("CD133", "CD44", "G-CIMP")
clinAgilent$threeGroup[clinAgilent$G_CIMP_STATUS %in% 'G-CIMP'] = "G-CIMP"
clinAgilent$threeGroup = as.factor(clinAgilent$threeGroup)
data.surv = Surv(clinAgilent$CDE_survival_time, event=clinAgilent$X_EVENT)
threeGroupFit = survfit(data.surv ~ threeGroup, clinAgilent)

plot(threeGroupFit, main='Agilent microarray',ylab='Survival probability',xlab='survival (days)', 
     col=c("red",'blue', 'green'), cex.axis=1.33, cex.lab=1.33,
     cex=1.75, conf.int=F, lwd=1.33)
legend('topright', c('CD133', 'CD44', "G-CIMP"), title="",
       col=c("red",'blue', 'green'),
       lwd=1.33, cex=1.2, bty='n', xjust=0.5, yjust=0.5)

#################### Try all patients regardless of Agilent or RNAseq ###################
data.surv = Surv(clinical$CDE_survival_time, event=clinical$X_EVENT)
coxPH = coxph(data.surv ~ CDE_DxAge  + gender + G_CIMP_STATUS + subtype  + CDE_radiation_any + CDE_chemo_tmz, 
              data=clinical, na.action="na.omit")
summary(coxPH)

dbDisconnect(db)