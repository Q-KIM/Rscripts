library(goseq)
setwd('~/Documents/RNAdata/danBatch1/bowtieGem/revHTSeq/GLMedgeR/140203_facsBatch/')

data = read.delim('140203_shortVSlong.txt')
up.genes <- as.integer(data$FDR < 0.1 & data$logFC > 0)
names(up.genes) <- data$ensembl_gene_id
table(up.genes)

down.genes <- as.integer(data$FDR < 0.1 & data$logFC < 0)
names(down.genes) <- data$ensembl_gene_id
table(down.genes)

# Model th bias from gene length of DE genes
null_model_up <- nullp(up.genes, genome = "hg19", id = "ensGene")
null_model_down <- nullp(down.genes, genome = "hg19", id = "ensGene")

# Calculate enrichment of KEGG enrichment
kegg_enrichmentUp <- goseq(null_model_up, genome = "hg19", id = "ensGene", 
                           test.cats = c("KEGG", "GO:BP","GO:MF"), method = "Wallenius")
kegg_enrichmentDown <- goseq(null_model_down, genome = "hg19", id = "ensGene", 
                             test.cats = c("KEGG", "GO:BP","GO:MF"), method = "Wallenius")

# Control for FDR
kegg_fdrs_up <- p.adjust(kegg_enrichmentUp[, 2], method = "BH")
kegg_enrichment_up <- cbind(kegg_enrichmentUp, FDR = kegg_fdrs_up)

kegg_fdrs_down <- p.adjust(kegg_enrichmentDown[, 2], method = "BH")
kegg_enrichment_down <- cbind(kegg_enrichmentDown, FDR = kegg_fdrs_down)

# Annotate the KEGG IDs
library(KEGGREST)
keggid2name <- keggList("pathway", "hsa")
head(keggid2name)

names(keggid2name) <- sapply(names(keggid2name), substring, 9)
kegg_enrichment <- cbind(kegg_enrichment_up, pathway = keggid2name[kegg_enrichment_up$category])
enriched_pathwaysUp <- kegg_enrichment_up[kegg_enrichment_up$FDR < 0.1, ]
dim(enriched_pathwaysUp)[1]

names(keggid2name) <- sapply(names(keggid2name), substring, 9)
kegg_enrichment <- cbind(kegg_enrichment_down, pathway = keggid2name[kegg_enrichment_down$category])
enriched_pathwaysDown <- kegg_enrichment[kegg_enrichment_down$FDR < 0.1, ]
dim(enriched_pathwaysDown)[1]

# Now annotate IDs
library(biomaRt)
mart <- useMart(biomart = "ensembl", dataset = "hsapiens_gene_ensembl")
results <- getBM(attributes = c("go_id", "definition_1006",
                                "name_1006"), filters = "go_id",
                 values = enriched_pathwaysDown$category, mart = mart)

enriched_pathwaysDownAnn = merge(enriched_pathwaysDown, results, by.x='category', by.y='go_id')

resultsUp <- getBM(attributes = c("go_id", "definition_1006",
                                "name_1006"), filters = "go_id",
                 values = enriched_pathwaysUp$category, mart = mart)
enriched_pathwaysUpAnn = merge(enriched_pathwaysUp, resultsUp, by.x='category', by.y='go_id')

write.table(enriched_pathwaysDownAnn, './140210_enrichedKEGGpathwaysLongTerm.txt', sep='\t')
write.table(enriched_pathwaysUpAnn, './140210_enrichedKEGGpathwaysShortTerm.txt', sep='\t')