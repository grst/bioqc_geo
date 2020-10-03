library(dplyr)
library(tidyr)
library(tibble)
library(readr)
library(magrittr)
library(data.table)

# Independent Validation with NGS data (ARCHS4)
## We perform the same analysis with expression data from ARCHS4.

## Prepare that data.
## Make the data look the same like the dumps from the oracle database.

### Normalize tissue names.
bioqc_gsm = read_csv("./data/bioqc_geo_oracle_dump/BIOQC_GSM_DATA_TABLE.csv", guess_max=1e6)
normalize_tissue = read_csv("./data/bioqc_geo_oracle_dump/BIOQC_NORMALIZE_TISSUES_DATA_TABLE.csv")
bioqc_tissue_set = read_csv("./data/bioqc_geo_oracle_dump/BIOQC_TISSUE_SET_DATA_TABLE.csv") %>%
  select(TISSUE, TGROUP, TISSUE_SET) %>%
  distinct()

gsm_tissue = bioqc_gsm %>%
  select("GSM", "GPL", "TISSUE_ORIG") %>%
  inner_join(normalize_tissue) %>%
  inner_join(bioqc_tissue_set)
# bioqc_gsm = NULL # free mem

write_csv(gsm_tissue, "./results/archs4/archs4_meta.csv")


### make signature, GSM, pvalue tuples.
load("data/archs4/Jitao David Zhang - ARCHS4-humanGregorGEOBioQC-cache.RData")
load("data/archs4/Jitao David Zhang - ARCHS4-mouseGregorGEOBioQC-cache.RData")

archs4HumanGregorGEOBioQC = 10^-archs4HumanGregorGEOBioQC # these are score, we want p-values
archs4MouseGregorGEOBioQC = 10^-archs4MouseGregorGEOBioQC

archs4_pdata_hsa = read_tsv("./data/archs4/Jitao David Zhang - ARCHS4-humanEset-phenoData.txt")
colnames(archs4HumanGregorGEOBioQC) = archs4_pdata_hsa$Sample_geo_accession
archs4_pvalues_hsa = data.table(archs4HumanGregorGEOBioQC, keep.rownames = "SIGNATURE") %>%
  melt(variable.name = "GSM", value.name = "PVALUE")

archs4_pdata_mmu = read_tsv("./data/archs4/Jitao David Zhang - ARCHS4-mouseEset-phenoData.txt")
colnames(archs4MouseGregorGEOBioQC) = archs4_pdata_mmu$Sample_geo_accession
archs4_pvalues_mmu = data.table(archs4MouseGregorGEOBioQC, keep.rownames = "SIGNATURE") %>%
  melt(variable.name = "GSM", value.name = "PVALUE")

# write output.
write_csv(rbind(archs4_pvalues_hsa, archs4_pvalues_mmu), "./results/archs4/archs4_res.csv")
