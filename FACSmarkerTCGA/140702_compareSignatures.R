# Compare veerhak and my FACS signatures
library(sqldf)
setwd('~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/signatureComparison/')

db <- dbConnect(SQLite(), dbname="~/Documents/public-datasets/cancerBrowser/tcgaData.sqlite")

probOverlap <- function (signature1, signature2, allGenes) {
  # the signatures should be a vector of gene names. All genes is all possible genes that were measured, also a vector of gene names
  overlap = intersect(signature1, signature2)
  
  # Use phyper (the hypergeometric distribution) to compute overlap.
  # phyper(q, m, n, k, lower.tail = FALSE, log.p = FALSE)
  # q = size of overlap-1; m=number of upregulated genes in experiment #1; n=(total number of genes on platform-m); k=number of upregulated genes in experiment #2.
  
  phyper(length(overlap) - 1, length(signature1), length(allGenes) - length(signature1), length(signature2), lower.tail=FALSE, log.p=FALSE)
  # The probability of getting a number larger than overlap by chance
}

########################## Read in the signatures ################################
rnaseqGem = read.delim("~/Documents/public-datasets/cancerBrowser/TCGA_GBM_exp_HiSeqV2-2014-05-02/genomicMatrix", row.names=1)

cd133Sig = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/140527_cd133Cutoff.txt", row.names=1)
cd44Sig = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/140527_cd44Cutoff.txt", row.names=1)
cd15 = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/CD15/140528_cd15Cutoff.txt", row.names=1)
aldh1 = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/ALDH1/140528_ALDH1Cutoff.txt", row.names=1)
itag6 = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/ITGA6//140528_ITGA6Cutoff.txt", row.names=1)
l1cam = read.delim("~/Documents/public-datasets/cancerBrowser/deDupAgilent/results/L1CAM/140528_L1CAMCutoff.txt", row.names=1)

fascSigs = list("CD133" = row.names(cd133Sig), "CD44" = row.names(cd44Sig), "CD15" = row.names(cd15),
               "ALDH1"=row.names(aldh1), "ITGA6"=row.names(itag6), "L1CAM"=row.names(l1cam))
rm(cd133Sig, cd44Sig, cd15, aldh1, itag6, l1cam)

tcgaSigs = read.delim('~/Documents/public-datasets/TCGA/classficationSignature/131022_danFixedTCGAsignature.txt')

########################## CD133 and proneural ########################## 
proCD133 = intersect(tcgaSigs$Proneural, row.names(cd133Sig))

# Use phyper the hypergeometric distribution to compute overlap. The probability of getting a number larger than overlap by chance
# phyper(q, m, n, k, lower.tail = FALSE, log.p = FALSE)
# q = size of overlap-1; m=number of upregulated genes in experiment #1; n=(total number of genes on platform-m); k=number of upregulated genes in experiment #2.

phyper(length(proCD133) - 1, length(row.names(cd133Sig)), length(row.names(rnaseqGem)) - length(row.names(cd133Sig)), length(tcgaSigs$Proneural), lower.tail=FALSE, log.p=FALSE)
# 8.666461e-16

########################## CD44 and Mesenchymal ########################## 
mesCD44 = intersect(tcgaSigs$Mesenchymal, row.names(cd44Sig))

phyper(length(mesCD44) - 1, length(row.names(cd44Sig)), length(row.names(rnaseqGem)) - length(row.names(cd44Sig)), length(tcgaSigs$Mesenchymal), lower.tail=FALSE, log.p=FALSE)
# 1.31642e-106

########################## CD15 and Mesenchymal ########################## 
probOverlap(tcgaSigs$Mesenchymal, row.names(cd15), row.names(rnaseqGem))
# 5.932462e-91
length(intersect(tcgaSigs$Mesenchymal, row.names(cd15)))

########################## CD15 and CD44 ########################## 
probOverlap(row.names(cd44Sig), row.names(cd15), row.names(rnaseqGem))
# Measure the degree of overlap
cd44_15 = intersect(row.names(cd44Sig), row.names(cd15))
length(cd44_15)/621

########################## CD133 and CD44 ########################## 
probOverlap(row.names(cd44Sig), row.names(cd133Sig), row.names(rnaseqGem))


################### Measure overlap between The subtypes called by FACS and TCGA subtypes #####################
subtypes = dbReadTable(db, "rnaSeqSubtyped", row.names='row_names')

xtabs(~ subtype + G_CIMP_STATUS, data=subtypes)
fisher.test(xtabs(~ subtype + G_CIMP_STATUS, data=subtypes))

fisher.test(xtabs(~ subtype + GeneExp_Subtype, data=subtypes[subtypes$GeneExp_Subtype %in% c('Proneural', 'Mesenchymal'),]))
fisher.test(xtabs(~ subtype + GeneExp_Subtype, data=subtypes[subtypes$GeneExp_Subtype %in% c('Proneural', 'Classical'),]))
fisher.test(xtabs(~ subtype + GeneExp_Subtype, data=subtypes[subtypes$GeneExp_Subtype %in% c('Proneural', 'Neural'),]))


subtypes$MesOther = "Mesenchymal"
subtypes$MesOther[!subtypes$GeneExp_Subtype %in% 'Mesenchymal'] = "Other"
xtabs(~ subtype + MesOther, data=subtypes)
fisher.test(xtabs(~ subtype + MesOther, data=subtypes))

subtypes$PromOther = "Proneural"
subtypes$PromOther[!subtypes$GeneExp_Subtype %in% 'Proneural'] = "Other"
xtabs(~ subtype + PromOther, data=subtypes)
fisher.test(xtabs(~ subtype + PromOther, data=subtypes))

################### Measure the actual signature scores using Mann Whitney test ################### 
wilcox.test(CD133 ~ PromOther, data=subtypes)
wilcox.test(CD44 ~ MesOther, data=subtypes)

########################## Use bionomial distribution to measure division of Mol subtype with FACS sig #######################

# Can CD44/ CD133 classification unequal in Neural?
neural = subtypes[subtypes$GeneExp_Subtype %in% 'Neural',]
xtabs(~ GeneExp_Subtype + subtype, data=neural)
binom.test(15, 15+13, p = 0.5) # p = 0.85

# Can CD44/ CD133 classification unequal in Classical?
classical = subtypes[subtypes$GeneExp_Subtype %in% 'Classical',]
xtabs(~ GeneExp_Subtype + subtype, data=classical)
binom.test(28, 28+14, p = 0.5) # p = 0.04

# Test if CD44 is significantly Mesenchymal
xtabs(~ GeneExp_Subtype + subtype, data=subtypes[subtypes$GeneExp_Subtype %in% 'Mesenchymal',])
binom.test(44, 44+11, p = 0.5) # 8.699e-06

# Test if CD133 is significantly Proneural
xtabs(~ GeneExp_Subtype + subtype, data=subtypes[subtypes$GeneExp_Subtype %in% 'Proneural',])
binom.test(37, 39, p = 0.5) # 2.841e-09

# Test if CD133 is significantly Classical
prop.test(36, 36+28, p = 0.5) # p = 0.3816

subtypeClassicfication = rbind(c(37,2), c(44, 11), c(15, 13), c(28, 14))
row.names(subtypeClassicfication) = c('Pro', 'Mes', 'Neu', 'Class')
pairwise.prop.test(subtypeClassicfication)

p.adjust(c(0.85, 0.04, 8.699e-06, 2.841e-09), method='fdr')