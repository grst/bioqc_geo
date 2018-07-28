stopifnot(suppressPackageStartupMessages(require(RColorBrewer)))
stopifnot(suppressPackageStartupMessages(require(ggplot2)))
stopifnot(suppressPackageStartupMessages(require(reshape2)))
stopifnot(suppressPackageStartupMessages(require(circlize)))

#########
# Library of reusable plotting function for
# the BioQC GEO analysis. 
########

#' Perform and Plot a PCA of an ExpressionSet
#' 
#' @param eset An ExpressionSet
esetPca = function(eset, title) {
  pca = prcomp(t(exprs(eset)))
  expVar <- function(pcaRes, n) {vars <- pcaRes$sdev^2; (vars/sum(vars))[n]}
  biplot(pca, col=c("#335555dd", "transparent"), cex=1.15,
         xlab=sprintf("Principal component 1 (%1.2f%%)", expVar(pca,1)*100),
         ylab=sprintf("Principal component 1 (%1.2f%%)", expVar(pca,2)*100),
         main=title)
}


#' Create a heatmap from a Matrix
#'
#' The matrix contains samples as columns and
#' tissue signatures as rows. 
#'
#' @param bioqc_res A Matrix containing the (transformed) p-values. 
bioqcHeatmap = function(bioqc_res, title) {
  hm.palette <- colorRampPalette(rev(brewer.pal(11, 'Spectral')), space='Lab')  
  mat.melted = melt(bioqc_res)
  ggplot(data=mat.melted, aes(x=Var2, y=Var1, fill=value)) + geom_tile() +
    coord_equal() +
    scale_fill_gradientn(colours = hm.palette(100)) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    ggtitle(title)
}


#' Create a migration chart from a matrix. 
#' 
#' matrix(c(5,3,0, 1,5,2, 4,4,0), nrow=3, byrow=T)
contamMigrationChart = function(matrix) {
  chordDiagram(melt(matrix))
}