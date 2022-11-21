library(plyr)
library(ggplot2)
library(tidyverse)
library("ggsignif")
library(openxlsx)

# setwd("/home/christopher.schmied/Desktop/HT_Docs/Projects/MeasureInt_AP/testOut/")
setwd("/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Colocalization/output/")

# ============================================================================
# 
#
#  DESCRIPTION: 
#              
#       AUTHOR: Christopher Schmied, 
#      CONTACT: 
#     INSITUTE: 
#
#         BUGS:
#        NOTES: 
# DEPENDENCIES: plyr - install.packages("plyr")
#
#
#      VERSION: 0.0.1
#      CREATED: 2022-10-28
#     REVISION: 
#
# ============================================================================
# user defined parameters

# =============================================================================
# function for getting the metadata from filename
# =============================================================================
# function that adds metadata as a column
read_table_filename <- function(filename){
  ret <- read.csv(filename, header = TRUE, stringsAsFactors = FALSE )
  # extracts from filename the metadata and adds as column
  ret$exp <- regmatches(basename(filename), regexpr('(^)MUT|WT|CTL(?=\\d_)', basename(filename), perl=TRUE))
  ret$set <- regmatches(basename(filename), regexpr('(?<=MUT|WT|CTL)\\d(?=_CHD8)', basename(filename), perl=TRUE))
  ret$stack <- regmatches(basename(filename), regexpr('(?<=_SINGLE)\\d*(?=_)', basename(filename), perl=TRUE))
  ret
}

# ==============================================================================
# only processes nuc results
nuc.file.list <- list.files(recursive=TRUE, pattern = ".*_MeasNuc.csv", full.names = TRUE )

# llply needs plyr package
nuc.filename.table <- llply(nuc.file.list, read_table_filename)

# now rbind is combining them all into one list
nuc.filename.combine <- do.call("rbind", nuc.filename.table)
nuc.filename.combine$X <- NULL
# ------------------------------------------------------------------------------
# only processes cell results
cell.file.list <- list.files(recursive=TRUE, pattern = ".*_MeasCell.csv", full.names = TRUE )

# llply needs plyr package
cell.filename.table <- llply(cell.file.list, read_table_filename)

# now rbind is combining them all into one list
cell.filename.combine <- do.call("rbind", cell.filename.table)

cell.filename.combine$X <- NULL
# ------------------------------------------------------------------------------
# only processes area results
area.file.list <- list.files(recursive=TRUE, pattern = ".*_Area.csv", full.names = TRUE )

# llply needs plyr package
area.filename.table <- llply(area.file.list, read_table_filename)

# now rbind is combining them all into one list
area.filename.combine <- do.call("rbind", area.filename.table)

# ------------------------------------------------------------------------------
nuc.cell.merge <- merge(nuc.filename.combine, cell.filename.combine, by = c('exp', 'set','stack'),suffixes = c(".nuc",".cell"))
nuc.cell.area.merge <- merge(nuc.cell.merge, area.filename.combine, by = c('exp', 'set','stack'))

nuc.cell.area.merge.corr <- nuc.cell.area.merge %>%
  mutate(across('exp', str_replace, 'CTL', 'WT'))

write.xlsx(nuc.cell.area.merge.corr, 'measureInt_result.xlsx')

nuc.cell.area.merge.filter <- nuc.cell.area.merge.corr %>% filter( Percent > 10)

nuc.cell.area.merge.corr %>% filter( Percent < 10)

# ------------------------------------------------------------------------------
wt <- subset(nuc.cell.area.merge.filter, exp == 'WT')
mut <- subset(nuc.cell.area.merge.filter, exp == 'MUT')

ggplot(nuc.cell.area.merge.filter, aes(x=factor(exp, level=c('WT', 'MUT')), y=Mean.nuc, fill=exp )) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  geom_signif(comparisons = list(c("MUT", "WT")),
              map_signif_level = TRUE,
              test = "wilcox.test") + 
  geom_jitter(width = 0.20) +
  ylim(0,300) +
  labs(title = "Mean intensity in cell area", caption = "Wilcoxon rank sum test: p-value = 0.008984") + 
  # ggtitle("Mean intensity in nuclei area") +
  xlab("Treatment") +
  ylab("Fluorescence (A.U.)")

test.nuc <- wilcox.test(wt$Mean.nuc, mut$Mean.nuc)
test.nuc

ggplot(nuc.cell.area.merge.filter, aes(x=factor(exp, level=c('WT', 'MUT')), y=Mean.cell, fill=exp)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  geom_signif(comparisons = list(c("MUT", "WT")),
              map_signif_level = TRUE,
              test = "wilcox.test") + 
  geom_jitter(width = 0.20) +
  ylim(0,300) +
  labs(title = "Mean intensity in cell area", caption = "Wilcoxon rank sum test: p-value = 0.9109") + 
  ggtitle("Mean intensity in cell area") +
  xlab("Treatment") +
  ylab("Fluorescence (A.U.)")

test.cell <- wilcox.test(wt$Mean.cell, mut$Mean.cell)
test.cell
# ------------------------------------------------------------------------------
ggplot(nuc.cell.area.merge.filter, aes(x=Mean.nuc)) + geom_histogram()

# ------------------------------------------------------------------------------
test <- nuc.cell.area.merge.corr %>% filter( set == 1 | set == 3 )

ggplot(test, aes(x=factor(exp, level=c('WT', 'MUT')), y=Mean.nuc, fill=exp )) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  geom_signif(comparisons = list(c("MUT", "WT")),
              map_signif_level = TRUE,
              test = "wilcox.test") + 
  geom_jitter(width = 0.20) +
  ylim(0,300) +
  ggtitle("Mean intensity in nuclei area") +
  xlab("Treatment") +
  ylab("Fluorescence (A.U.)")


ggplot(test, aes(x=factor(exp, level=c('WT', 'MUT')), y=Mean.cell, fill=exp)) +
  geom_boxplot() +
  theme_classic(base_size = 20) +
  geom_signif(comparisons = list(c("MUT", "WT")),
              map_signif_level = TRUE,
              test = "wilcox.test") + 
  geom_jitter(width = 0.20) +
  ylim(0,300) +
  ggtitle("Mean intensity in cell area") +
  xlab("Treatment") +
  ylab("Fluorescence (A.U.)")
