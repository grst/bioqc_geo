###############################
# Library to read and write data from and to the database. 
# need to source db.R before using!
###############################

stopifnot(suppressPackageStartupMessages(require(stringr)))
stopifnot(suppressPackageStartupMessages(require(data.table)))

#' Escape a string for SQL
#' 
#' @note this is not to be understood as being safe in any way. Use only when prepared 
#' statements are note an option
#' @param text the string to escape.
db_escape = function(text) {
  return(gsub("'", "''", text))
}

#' Read a GMT file and write it to the signatures database
#' 
#' @param gmt_file path to gmt file
gmt2db = function(gmt_file, source=NULL) {
  if(is.null(source)) {
    source = basename(gmt_file)
  }
  gmt <- readGmt(gmt_file)
  gmt_list = lapply(gmt, function(line) {
    return(list(id=NA, name=line$name, source=source, desc=line$desc, genes=paste(line$genes, collapse=',')))
  })
  gmt_table = do.call(rbind.data.frame, gmt_list)
  dbAppendDf("BIOQC_SIGNATURES", gmt_table)
}

#' Download all signatures from the database and combine them in one gmt. 
#' 
#' Uses the database id as signature identifier. 
#' @param output_file
db2gmt = function(output_file) {
  signatures = dbGetQuery(mydb, "select * from bioqc_signatures
                           order by source, name")
  if(file.exists(output_file)) {
    # need to clear the file, as we are appending later. 
    file.remove(output_file)
  }
  for (i in 1:nrow(signatures)) {
    row = signatures[i, ]
    name = as.character(row$ID)
    desc = str_c(row$SOURCE, row$NAME, sep=":")
    genes = str_c(unlist(str_split(row$GENE_SYMBOLS, ",")), collapse="\t") 
    cat(paste(str_c(name, desc, genes, sep="\t"), "\n"), file=output_file, append=TRUE)
  }
}

#' Read a BioQC result file (pvalue-matrix) and write it to 
#' the BIOQC_RES table. 
#' 
#' Signature names need to be the numeric ids from the signatures
#' table. Ideally, create your gmt file with db2gmt
melt_bioqc = function(bioqc_res_matrix, cutoff=.1) {
  res.molten = data.table(melt(bioqc_res_matrix, id.vars="rn"))
  setcolorder(res.molten, c(2,1,3))
  res.molten.f = res.molten[value<cutoff,]
  # cannot insert high precision doubles otherwise (bug in RJBDC)
  res.molten.f$value = as.character(res.molten.f$value)
  return(res.molten.f)
  #dbAppendDf("UDIS_RES", res.molten.f)
}

#' Add a signature set to the database.
#' 
#' Map the signature_name, source_file combination back to the original signature id. 
#' This is possible because of the unique constraint. 
#' 
#' @param table the mapping table for the given tissue set (signature, signature_source, tissue, tissue_group)
#' @param tissue_set_name Name of the tissue set, e.g. gtex_rock_solid
signatureset2db = function(table, tissue_set_name) {
  dbSendUpdate(mydb, "truncate table bioqc_tmp_tissue_set")
  table = data.table(table)
  table = table[,comment:=NULL]
  table = melt(table, id.vars = c('signature', 'signature_source', 'group'), na.rm=TRUE)
  table = table[,variable:=NULL]
  table = table[,tissue_set:=rep(tissue_set_name, nrow(table))]
  table = table[!is.na(group),]
  dbAppendDf("BIOQC_TMP_TISSUE_SET", table)
  dbSendUpdate(mydb, "
      insert into bioqc_tissue_set 
          select  bs.id
                , tts.tissue
                , tts.tgroup
                , tts.tissue_set
          from bioqc_tmp_tissue_set tts
          join bioqc_signatures bs
          on tts.signature_name = bs.name and tts.signature_source = bs.source
  ")
}