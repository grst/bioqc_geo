stopifnot(suppressPackageStartupMessages(require(ribiosAnnotation)))
stopifnot(suppressPackageStartupMessages(require("RJDBC")))
source("lib/db/.db_creds.R")

drv <- RJDBC::JDBC("oracle.jdbc.OracleDriver", system.file("drivers", 
                                                           "ojdbc14.jar", package = "ribiosAnnotation"))
str <- paste("jdbc:oracle:thin:", pg_user, "/", pg_pass, 
             "@", pg_dbname, ".kau.roche.com:", pg_port, sep = "")
mydb <- dbConnect(drv, str)

#' Wapper for \code{\link{dbWriteTable}}.
#'
#' Calls dbWriteTable with append=TRUE and overwrite=FALSE as defaults. 
#' 
#' @param df
#' @param table
dbAppendDf = function(table, df) {
  #tmp = tempfile()
  #write.csv(df, file=tmp, fileEncoding='utf-8')
  # system(sprintf(
  #  'PGPASSFILE=/homebasel/biocomp/sturmg/.pgpass /apps64/postgresql-9.2.2/bin/psql -U sturmg -c "\\copy %s from %s with csv header encoding \'UTF8\' delimiter as \',\'"', table, tmp))
  dbWriteTable(mydb, name=table, value=df, append=TRUE, overwrite=FALSE)
}