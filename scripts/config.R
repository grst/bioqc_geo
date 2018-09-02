FDR_THRES = 0.01 # overall false-discovery rate
TAU = polyroot(c(FDR_THRES, -2, 1))[1]  # see 'heterogeneity_test.Rmd'. FDR cutoff for the individual tests.
