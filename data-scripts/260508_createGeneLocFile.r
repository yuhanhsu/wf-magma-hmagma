# code to generate gene.loc file containing updated gene names and GRCh37 coordinates

rm(list=ls())

library(dplyr)
#BiocManager::install('rtracklayer')
library(rtracklayer) # readGFF

# download and parse GENCODE v49 GTF for GRCh37
#https://www.gencodegenes.org/human/release_49lift37.html
#description: evidence-based annotation of the human genome (GRCh38), version 49 (Ensembl 115), mapped to GRCh37 with gencode-backmap
#date: 2025-07-08
url <- 'https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_49/GRCh37_mapping/gencode.v49lift37.basic.annotation.gtf.gz'
gtf <- readGFF(url)

# extract relevant rows and columns for protein-coding genes on chr1-22,X,Y
outDf <- gtf %>% mutate(chr=gsub('chr','',seqid)) %>%
	subset(type=='gene' & gene_type=='protein_coding' & 
	#!grepl('ENSG',gene_name) & 
	chr %in% c(1:22,'X','Y')) %>%
	select(gene_name,chr,start,end)

dim(outDf) # 20209 x 4
length(unique(outDf$gene_name)) # 20180 unique gene names (29 genes have >1 chr pos)

# check duplicated gene name entries
x <- names(which(table(outDf$gene_name)>1)) # 29 gene names
y <- subset(outDf,gene_name %in% x)
z <- y %>% group_by(gene_name) %>%
	summarize(chr=paste0(unique(chr),collapse=','),
		start=paste0(unique(start),collapse=','),
		end=paste0(unique(end),collapse=','))
data.frame(z)
# 19 duplicated genes on X vs. Y chromosome (X entry comes before Y entry)
# 10 other duplicated genes with similar coordinates on same chromosome

# remove duplicated gene names by keeping first entry only
outDf <- outDf %>% subset(!duplicated(gene_name))
dim(outDf) # 20180

write.table(outDf,'../data/260508_GENCODE_v49_GRCh37_ProteinCoding.gene.loc',
	sep='\t',quote=F,col.names=F,row.names=F)

