#######################################################################################
# Fit a linear model to each (Signature, Reference Signature) pair and derive
# a correlation-corrected p-value.
#
# The correlation-corrected p-value is derived from the deviation of a point
# from the linear model, assuming normal distribution of the residues.
#
# OUTPUT
#    saves RDATA object to MODEL_FILE containing
#       * `models` a list[[reference_tissue]][[signature]] containing `rlm` models
#       * `data_corr` a dataframe derived from data2 containing additionally
#           the correlation-corrected p-value. It contains
#           the following columns
#            - PVALUE the original BioQC Pvalue of the signature
#            - score absLog10p of PVALUE
#            - qvalue: FDR-adjusted PVALUE
#            - REF_PVALUE: the original BioQC pvalue of the reference signature
#            - p_corr: P-value generated from linear model
#            - q_corr: fdr-adjusted p_corr
#
########################################################################################

library(tidyr)
library(dplyr)
library(tibble)
library(readr)
library(magrittr)
library(stringr)
library(MASS)
library(BioQC)
library(foreach)
library(doMC)
registerDoMC(cores = min(parallel::detectCores(), 8))

# Output file
# MODEL_FILE = "results/archs4/archs4_models.RData"
# DATA_FILE = 'results/archs4/archs4_data_processed.RData'

# MODEL_FILE = "results/models.RData"
# DATA_FILE = 'results/data_processed.RData'

args = commandArgs(TRUE)

DATA_FILE = args[1]
MODEL_FILE = args[2]

message("loading data\n")
# load preprocessed data
load(DATA_FILE)

#' calculate a correlation corrected pvalue for a signature (compare signature scores against the scores
#' of the reference signature)
process_tgroup = function(df) {
  tgroup = df$TGROUP[1]
  signature = df$SIGNATURE[1]
  model = models[[tgroup]][[signature]]
  df$sigma = sigma(model)
  df$slope = model$coefficients[[2]]
  df$intercept = model$coefficients[[1]]
  df
}

# calculate the rlm models for each pair (signature, reference_signature)
message("fitting models\n")
models = foreach (ref_sig=reference_signatures$REF_SIG,
                  tgroup=reference_signatures$TGROUP,
                  .final = function(x) setNames(x, reference_signatures$TGROUP)) %dopar% {
                    tmp_models = list()
                    for (sig in unique(data2$SIGNATURE)) {
                      ref_scores = data2 %>%
                        filter(TGROUP == tgroup, SIGNATURE == ref_sig) %>% .[["score"]]
                      sig_scores = data2 %>%
                        filter(TGROUP == tgroup, SIGNATURE == sig) %>% .[["score"]]
                      tmp_models[[sig]] = rlm(sig_scores~ref_scores)
                    }
                    tmp_models
                  }

# add slope and intercept to dataframe
message("Updating dataframe\n")
data_corr = data2 %>%
  group_by(TGROUP, SIGNATURE) %>%
  do(process_tgroup(.))

save(models, data_corr, file=MODEL_FILE, compress = FALSE)
