#######################################################################################
# preprocess data from BioQC database dump for heterogeneity analysis.
#
# OUTPUT
#    saves RDATA object to DATA_FILE containing
#       * `data2` essentially contains (study, signature, pvalue) pairs
#         combined with the tissue annotation and the reference signature
#       * `bioqc_meta` contains information for each sample (platform, tissue, tissue_group)
#       * `selected_signatures` list of names of signatures selected for
#         this study
#       * `reference_signatures` contains (reference_signature, tissue) pairs
########################################################################################

library(BioQC)
library(stringr)
library(dplyr)

# Output file
# BIOQC_RES_FILE = "data/bioqc_geo_oracle_dump/BIOQC_RES_DATA_TABLE.csv"
# BIOQC_META_FILE = "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_SELECTED_SAMPLES_TSET_DATA_MATERIALIZED VIEW.csv"
# DATA_FILE = 'results/data_processed.RData'

# BIOQC_RES_FILE = "./results/archs4/archs4_res.csv"
# BIOQC_META_FILE = "./results/archs4/archs4_meta.csv"
# DATA_FILE = 'results/archs4/archs4_data_processed.RData'

args = commandArgs(TRUE)

BIOQC_RES_FILE = args[1]
BIOQC_META_FILE = args[2]
DATA_FILE = args[3]


#' prefix signature names with their source to make the names unique.
#'
#' for this analysis, for simplicity, we make the signature name a unique primary key
#' and prefix BIOQC_, BASELINE_ or GTEX_ respectively.
#'
#' @param df dataframe with a SIG_SOURCE and a SIG_NAME column
prefix_signatures = function(df) {
  df %>%
    mutate(SIG_NAME = ifelse(SIG_SOURCE == "gtex_v6_gini_solid.gmt",
                             str_c("GTEX", SIG_NAME, sep="_"),
                             SIG_NAME)) %>%
    mutate(SIG_NAME = ifelse(SIG_SOURCE == "expr.tissuemark.affy.roche.symbols.gmt",
                             str_c("BIOQC", SIG_NAME, sep="_"),
                             SIG_NAME)) %>%
    mutate(SIG_NAME = ifelse(SIG_SOURCE == "baseline_signatures.gmt",
                             str_c("BASELINE", SIG_NAME, sep="_"),
                             SIG_NAME))
}


# List of (sample, signature, pvalue) pairs
bioqc_res = read_csv(BIOQC_RES_FILE)

# list of signatures with names
bioqc_signatures = read_csv("data/bioqc_geo_oracle_dump/BIOQC_SIGNATURES_DATA_TABLE.csv") %>%
  select(ID, SIG_NAME = NAME, SIG_SOURCE = SOURCE) %>%
  prefix_signatures()

# meta information for samples, e.g. year, tissue etc.
bioqc_meta = read_csv(BIOQC_META_FILE) %>%
  filter(TISSUE_SET == 'gtex_solid') %>%  # only gtex solid, as we require to have the reference signatures.
  select(GSM, GPL, TISSUE, TGROUP) # drop tissue set, as it is unique

# table organizeing signatures in tissue-sets (e.g. bioqc_solid, gtex_solid, ...)
bioqc_tissue_set = read_csv("data/bioqc_geo_oracle_dump/BIOQC_TISSUE_SET_DATA_TABLE.csv") %>%
  inner_join(bioqc_signatures, by = c("SIGNATURE"="ID"))

# Full-blown join. Save intermediate result due to runtime.
data = bioqc_res %>%
  mutate(score = absLog10p(PVALUE)) %>%
  inner_join(bioqc_signatures, by = c("SIGNATURE" = "ID")) %>%
  inner_join(bioqc_meta, by = c("GSM" = "GSM"))
bioqc_res = NULL # free RAM

###############################################
## Select signatures of interest
selected_signatures = bioqc_tissue_set %>%
  filter(TISSUE_SET == 'gtex_solid' | TISSUE_SET == 'bioqc_solid') %>%
  select(SIGNATURE = SIG_NAME) %>%
  distinct()

# random control signature
random_signature = bioqc_signatures %>%
  filter(SIG_NAME == 'BASELINE_random_100_0' | SIG_NAME == 'BASELINE_awesome_housekeepers') %>%
  select(SIGNATURE = SIG_NAME)

selected_signatures = rbind(selected_signatures, random_signature)

# reference signatures based on 'gtex_solid' for a a selected set of tissues.
reference_signatures = bioqc_tissue_set %>%
  filter(TISSUE_SET == 'gtex_solid') %>%
  select(REF_SIG = SIG_NAME, TGROUP) %>%
  distinct()

# bind signature names, reference signatures and adjusted pvalues to data
data2 = data %>%
  mutate(SIGNATURE = SIG_NAME) %>%
  select(-SIG_NAME, -SIG_SOURCE) %>%
  semi_join(selected_signatures, by = c("SIGNATURE")) %>%
  semi_join(reference_signatures, by = c("TGROUP")) %>%
  mutate(qvalue = p.adjust(PVALUE, method="fdr")) %>%
  arrange(GSM)
data = NULL # free RAM

# add reference scores to the reference signatures
reference_scores = reference_signatures %>%
  inner_join(data2 %>% select(-TGROUP), by = c("REF_SIG" = "SIGNATURE")) %>%
  arrange(GSM) %>%
  select(REF_SIG, REF_TGROUP=TGROUP, GSM=GSM, REF_PVALUE = PVALUE, ref_score = score)

# add reference scores to the data
data2 = data2 %>%
  inner_join(reference_scores, by = c("GSM" = "GSM", "TGROUP" = "REF_TGROUP"))

# save results to save runtime
save(data2,
     bioqc_meta,
     selected_signatures,
     reference_signatures,
     bioqc_signatures,
     file = DATA_FILE)

