library(GenomicFeatures)
library(ChIPseeker)
library(clusterProfiler)
library(org.Hs.eg.db)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene

# read peak files generated by MACS2
data_anti_H3K18la <- readPeakFile("./data/SRR20073451_summits.bed")
data_input <- readPeakFile("./data/SRR20073452_summits.bed")

# chip peaks coverage plot

plot1 = covplot(data_input, weightCol="V5")
plot2 = covplot(data_anti_H3K18la, weightCol="V5")

ggsave("./results/input_coverage.pdf", plot1, width=40, height=30)
ggsave("./results/anti_H3K18la_coverage.pdf", plot2, width=40, height=30)

# merge as a list
peaks <- list(input=data_input, anti_H3K18la=data_anti_H3K18la)

# Profile of ChIP peaks binding to TSS regions
promoter <- getPromoters(TxDb=txdb,
                         upstream=3000,
                         downstream=3000)

tagMatrixList <- lapply(peaks, getTagMatrix, windows=promoter)

peakAnnoList <- lapply(peaks, 
                       annotatePeak, 
                       TxDb=txdb,
                       tssRegion=c(-3000, 3000),
                       annoDb="org.Hs.eg.db")

# visualization
# feature distribution
plot3 = plotAnnoBar(peakAnnoList)
ggsave("./results/peak_anno_bar.pdf", plot3, width=12, height=6)

# annotation overlap 
plot4 = upsetplot(peakAnnoList$anti_H3K18la, vennpie=T) +
  ggtitle("anti_H3K18la")
ggsave("./results/peak_anno_overlap.pdf", plot4, width=12, height=6)

plot5 = plotDistToTSS(peakAnnoList,
                      title="Distribution of transcription factor-binding loci 
                      \n relative to TSS")
ggsave("./results/peak_anno_tss.pdf", plot5, width=12, height=6)


# functional enrichment
genes = lapply(peakAnnoList, function(i) as.data.frame(i)$geneId)
names(genes) = sub("_", "\n", names(genes))
compKEGG <- compareCluster(geneCluster   = genes,
                           fun           = "enrichKEGG",
                           pvalueCutoff  = 0.05,
                           pAdjustMethod = "BH")
plot6 = dotplot(compKEGG, showCategory = 15, 
                title = "KEGG Pathway Enrichment Analysis")
ggsave("./results/peak_anno_kegg.pdf", plot6, width=12, height=6)


