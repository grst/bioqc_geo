#!/bin/env Rscript

########
# Script to install all AnnotationDbi Chip annotation packages
# that can be used to annotate chip symbols for one of the chips 
# in the database. 
#
# the GEOMetabase provides a mapping from GPLXXXX to the annotation package.
########

source("http://bioconductor.org/biocLite.R")
source("lib/db.R")

annotationPackages = dbGetQuery(mydb, "select distinct bioc_package from gpl where bioc_package is not null")
for (pkg in annotationPackages$bioc_package) {
    biocLite(sprintf("%s.db", pkg))
}
