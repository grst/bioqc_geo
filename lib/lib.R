###################
# Library for BioQC GEO analysis. 
# 
# Collection of functions that are used in 
# multiple analyses. 
##################


#' Normalize a vector between 0 and 1
#'
#' @param x A vector.
norm01 = function(x){
  (x-min(x))/(max(x)-min(x))
}


#' Median and standard deviation of all values 
#' within the 90% interval. 
robust_stats = function(x) {
  qts = quantile(x, c(.05, .95))
  xq = x[x >= qts[1] & x <= qts[2]]
  return(list(mean(xq), sd(xq)))
}


#' Trim leading and trailing whitespace
trim = function (x) gsub("^\\s+|\\s+$", "", x)


#' Collapse multiple signatures that belong to the same tissue into one.
#' 
#' BioQC comes with multiple signatures per tissue e.g. Liver, Liver_fetal
#' Liver_NGS, ...
#' The annotation in the GEO is more coarse than that, only stating 'liver'. 
#' This function therefore collapses multiple signatures into one by taking the
#' maximum score of the selected signatures. 
#' 
#' @param table
#' @param sig.list list of the signature names corresponding to the rownames of the table
#' @param new.name new row name for the collapsed rows. 
#' @param method function to be applied to each column. Defaults to max.  
collapseSignatures = function(table, sig.list, new.name, method=max) {
  row.collapsed = apply(table[sig.list, ], 2, method)
  row.collapsed.df = data.frame(t(unlist(row.collapsed)))
  rownames(row.collapsed.df) = c(new.name)
  table.collapsed = rbind(table, row.collapsed.df)
  return(table.collapsed[-which(rownames(table.collapsed) %in% sig.list), ,drop=FALSE])
}

#' Choose the most enriched signature for a given tissue
#' 
#' @param table.column column of the table with BioQc score
#' @param sig.list list of the signature names that are associated with the tissue
chooseSignature = function(table.column, sig.list, method=max) {
  sig.vals = table.column[rownames(table.column) %in% sig.list,,drop=F]
  return(rownames(sig.vals[sig.vals[,1,drop=F] == max(sig.vals[,1,drop=F]),,drop=F])[1])
}

#' Add random noise to a matrix
#' 
#' @param matrix matrix to which the noise should be added
#' @param fractionAffected fraction of elements of the matrix that will be noisy
#' @param stdv stdv of the noise
#' @param mean mean of the noise
addNoise = function(matrix, fractionAffected=.1, stdv=2, mean=9) {
  noise = matrix(rnorm(nrow(matrix)*ncol(matrix), mean=mean, sd=stdv), nrow=nrow(matrix), byrow=FALSE)
  addNoise = matrix(runif(nrow(matrix)*ncol(matrix)), nrow=nrow(matrix), byrow=FALSE) < fractionAffected
  matrix = matrix + addNoise*noise
  return(matrix)
}
