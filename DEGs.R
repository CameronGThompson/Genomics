rm(list=ls())

#Load in DESeq2 and the 3 visualisation packages 
#for custom plotting and heatmap steps
library(DESeq2)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)

setwd("C:/Users/iy21106/Genome_Biology_and_Genomics/W7/Data")
getwd()

#Import data
raw_data <- read.table("Count_matrix.txt", header=TRUE, sep="\t", check.names=FALSE)

#Verify the import
head(raw_data)

#Assign gene identifiers
rownames(raw_data) <- raw_data[, 1]

#Isolate the numeric counts
counts <- raw_data[, 2:9]

#Verify the results
head(counts)

#Create the metadata
sample_info <- data.frame(condition = factor(c(rep("COVID19", 4), rep("Control", 4))), 
                          row.names = colnames(counts))

#Verify
sample_info

#Initialise the DESeq2 object
dds <- DESeqDataSetFromMatrix(countData = counts, colData = sample_info, design = ~ condition)

#Pre-filtering
keep <- rowSums(counts(dds)) >= 10
dds <- dds[keep,]

#Perform the statistical analysis
dds <- DESeq(dds)

#Extracting the results
res <- results(dds, contrast = c("condition", "COVID19", "Control"))

#Sorting by significance
resOrdered <- res[order(res$padj), ]

#Converting to a data frame
res_df <- as.data.frame(resOrdered)

#VST (Variance Stabilising Transformation) normalises the data for plotting
vsd <- vst(dds, blind = FALSE)

# A. PCA PLOT: Check for global sample clustering
plotPCA(vsd, intgroup="condition") +
  theme_bw() +
  labs(title = "PCA Plot")

#Make MA (Minus vs. Average) plot
plotMA(res, main = "MA Plot")

# --- Logic for Custom Categorisation ---
# We create a 'Sig' column based on adjusted p-value (<0.05) and Fold Change (>1).
res_df$Sig <- ifelse(res_df$padj < 0.05 & abs(res_df$log2FoldChange) > 1,
                     "Significant", "Not Sig")

#Make volcano plot
ggplot(res_df, aes(x=log2FoldChange, y=-log10(padj), color=Sig)) +
  geom_point(alpha=0.4) +
  scale_color_manual(values = c("grey", "red")) +
  theme_bw() +
  labs(title = "Volcano Plot: COVID19 vs Control")

#Define which genes are significant (Adjusted P < 0.05)
sig_genes <- rownames(res_df[which(res_df$padj < 0.05), ])

#Run the heatmap

pheatmap(assay(vsd)[sig_genes, ], scale = "row", show_rownames = FALSE,
         annotation_col = sample_info)

#Heatmap of top 50 expressed genes
pheatmap(assay(vsd)[head(rownames(resOrdered), 50), ], scale = "row", annotation_col = sample_info)

#Extract all normalised counts
norm_counts <- counts(dds, normalized=TRUE)

norm_counts_sorted <- norm_counts[rownames(resOrdered), ]

master_table <- cbind(res_df, norm_counts_sorted)

master_final <- cbind(GeneID = rownames(master_table), master_table)

write.csv(master_final, "COVID_vs_Control_Master_Results.csv", row.names = FALSE)
