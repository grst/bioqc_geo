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
#           the correlation-corrected p-value. 
########################################################################################

library(MASS)
library(BioQC)
library(stringr)
library(foreach)
library(doMC)
registerDoMC(cores = parallel::detectCores())
library(tidyverse)

# load pvalue cutoffs
source("config.R")

# Output file
# MODEL_FILE = "results/archs4/archs4_models.RData"
# DATA_FILE = 'results/archs4/archs4_data_processed.RData'

# MODEL_FILE = "results/models.RData"
# DATA_FILE = 'results/data_processed.RData'

args = commandArgs(TRUE)

MODEL_FILE = args[1]
DATA_FILE = args[2]

## testis has too few values in archs4 -> ignore. 
#reference_signatures = reference_signatures %>% filter(TGROUP != "testis")

# load preprocessed data
load(DATA_FILE)


#' calculate a correlation corrected pvalue for a signature (compare signature scores against the scores
#' of the reference signature)
#' @param tgroup annotated tissue (-> used to find reference signature)
#' @param sig signature of interest
#' @param ref_score for the given sample, score of the reference signature
#' @param sig_score for the given sample, score of the signature of interest
correlation_corrected_pvalue = Vectorize(function(tgroup, sig, ref_score, sig_score) {
  tryCatch({
    model = models[[tgroup]][[sig]]
    # ref_scores = variable name of linear model; see chunk above
    predicted = predict(model, newdata=data.frame(ref_scores=c(ref_score)))
    # if positive residue -> more than expected -> likely heterogenous (test with normal distribution)
    residue = sig_score - predicted 
    # minimal sigma to avoid numerical problems with perfect correlations (reference against itself)
    sd = max(sigma(model), 0.01) 
    return(pnorm(residue, mean=0, sd=sd, lower.tail = FALSE))
  }, error = function(e) {
    print(e)
    print(paste(tgroup, sig))
  })
})



# calculate the rlm models for each pair (signature, reference_signature) 
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

# add correlation corrected p-value and correct for multiple testing. 
data_corr = data2 %>% 
  filter(qvalue < FDR_THRES) %>% 
  mutate(pcorr = correlation_corrected_pvalue(TGROUP, SIGNATURE, ref_score, score)) %>%
  mutate(pcorr_adj = p.adjust(pcorr, method="bonferroni")) %>% 
  mutate(pcorr_qvalue = p.adjust(pcorr, method="fdr"))

save(models, data_corr, file=MODEL_FILE)
