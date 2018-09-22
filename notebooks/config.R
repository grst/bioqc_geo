FDR_THRES = 0.01 # overall false-discovery rate
TAU = Re(polyroot(c(FDR_THRES, -2, 1))[1])  # see 'heterogeneity_test.Rmd'. FDR cutoff for the individual tests.
SEVERE_THRES = 0.05 # samples that don't have their reference signature enriched with a pvalue < SEVERE_THRES are eligible for "severe contamination"
