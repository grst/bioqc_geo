# Setup Database {#setup-database}

In this chapter, we describe

* how we use an SQL database system (DBS) to hold all data relevant for the study
* the design of the database
* how we load the data into the DBS



We store meta information for GEO samples and BioQC p-values in
an Oracle 11g database. We combine the metadata from [GEOmetadb](https://www.bioconductor.org/packages/release/bioc/vignettes/GEOmetadb/inst/doc/GEOmetadb.html)
with tables to store signature scores generated with
[BioQC](https://accio.github.io/BioQC) and manually curated annotations.

If you want to reproduce the database, have a look at the additional repository
[grst/Bioqc_GEO_Analysis](https://github.com/grst/BioQC_GEO_analysis). A
dump of the database as `csv` files is available within the resources of this
document, which can also be found on GitHub:
[grst/bioqc_geo](https://github.com/grst/bioqc_geo)

The following figure shows the database scheme used for the study as entity-relationship (ER) diagram:

<div class="figure">
<img src="../db/design/er_diagram.png" alt="Entitiy relationship diagram of the *BioQC* database scheme. Click the [here](https://github.com/grst/BioQC_GEO_analysis/raw/master/db/design/er_diagram.pdf) for an enlarged version. Greenish tables are imported and adapted from GEOmetadb. Yellowish tables are additional tables designed for this study. Three dots (...) indicate columns from GEOmetadb which have been omitted in the visualisation because they are not relevant for this study."  />
<p class="caption">(\#fig:unnamed-chunk-2)Entitiy relationship diagram of the *BioQC* database scheme. Click the [here](https://github.com/grst/BioQC_GEO_analysis/raw/master/db/design/er_diagram.pdf) for an enlarged version. Greenish tables are imported and adapted from GEOmetadb. Yellowish tables are additional tables designed for this study. Three dots (...) indicate columns from GEOmetadb which have been omitted in the visualisation because they are not relevant for this study.</p>
</div>

## Tables explained

### GEOmetadb
* **BIOQC_GSM**: *from GEOmetadb*, meta information for all *Samples* in GEO
* **BIOQC_GPL**: *from GEOmetadb*, list of all *Platforms* (*e.g.* different types of microarrays) referenced in GEO.
* **BIOQC_GSE**: *from GEOmetadb*, list of *Series* (collections of samples) in GEO.
* **BIOQC_GSE_GPL**: *from GEOmetadb*, relation of *Series* and *Platforms*. Columns containing Series/Platform-specific gene expression statistics have been added which are used for a simple quality control.

### BioQC
* **BIOQC_TISSUES**: List of all tissues manually annotated in [Normalize Tissues](#normalize-tissues).
* **BIOQC_NORMALIZE_TISSUES**: Stores the [manually curated](#normalize-tissues) mapping of the original tissue name to a normalized tissue name.
* **BIOQC_SIGNATURES**: Stores gene signatures imported from a [GMT file](http://software.broadinstitute.org/cancer/software/gsea/wiki/index.php/Data_formats#GMT:_Gene_Matrix_Transposed_file_format_.28.2A.gmt.29).
* **BIOQC_TISSUE_SET**: Stores the [manually curated](#tissue-signatures) mapping of tissues to 'expected signatures'.
* **BIOQC_RES**: Stores the p-value generated with *BioQC* for each signature in **BIOQC_SIGNATURES** and each samples in **BIOQC_GSM**.
* **BIOQC_BIOQC_SUCCESS**: List of all studies on which we successfully ran *BioQC*. This serves as 'background' for our analysis.


## Import GEOmetadb

First, we need to extract a list of tables:

```r
gdb = dbConnect(SQLite(), file.path(DATA_DIR, "geometabase/GEOmetadb.sqlite"))
tables = dbListTables(gdb)
writeLines(tables, file(file.path(DATA_DIR, "geometabase/tables.txt")))
```

Then, we use a [conversion script](https://github.com/grst/BioQC_GEO_analysis/blob/master/db/geometadb2csv.sh) to
export the SQL schema and the tables as csv, which can be easily imported into the Oracle DBS.

We adjusted the [GEOmetadb schema](https://github.com/grst/BioQC_GEO_analysis/blob/master/db/geometadb_schema.sql) to match
Oracle datatypes.

Once the tables are imported, we check if all the tables have the same number of rows:

```r
# check for consistency
for(table in tables) {
  count.query = sprintf("select count(*) from %s", table)
  count.query.ora = sprintf("select count(*) from bioqc_%s", table)
  print(count.query)
  expect_equal(dbGetQuery(gdb, count.query)[[1]], dbGetQuery(mydb, tolower(count.query.ora))[[1]])
}
```


### Fix foreign key constraints

Unfortunately, foreign key constraints are not enabled in the GEOmetadb SQLite database. It turned out that the GEOmetadb is not entirely consistent when trying to add such constraints in Oracle. We fixed missing
parent keys by adding "stub" entries to the tables. The procedure is documented in
[this SQL script](https://github.com/grst/BioQC_GEO_analysis/blob/master/db/update_geometabase.sql).


### Extract Tissue annotation

The tissue annotation for each sample is hidden in the `characteristics_ch1` column of the `BIOQC_GSM` table. Since this information is
essential for our study, we parsed it into a separate column using a regular expression. The procedure is documented in
[this SQL script](https://github.com/grst/BioQC_GEO_analysis/blob/master/db/update_geometabase.sql).


### Load annotation information

To run [BioQC](https://accio.github.io/BioQC), gene symbols need to be annotated in the gene expression matrix.
To retrieve gene symbols, we are aware of two feasible possibilities:

* the Bioconductor annotation packages (listed in GEOmetadb `gpl.bioc_package`)
* use the GEO `annot_gpl` files ("in general available for all GSE that are referenced by a GDS"[^1])

[^1]: https://bioconductor.org/packages/release/bioc/manuals/GEOquery/man/GEOquery.pdf

To find out for which GSE in particular the latter option exists, we parsed the directory structure of the
GEO ftp server:


```bash
lftp -c "open ftp://ftp.ncbi.nlm.nih.gov/geo/platforms/ && find && exit" > gpl_annot_ftp_tree.txt
grep annot.gz gpl_annot_ftp_tree.txt | cut -d"/" -f5 | cut -d"." -f1 > gpl_annot.txt
```

We add this information the the `BIOQC_GPL` table as a boolean flag indicating whether the respective
platform has an annotation file.


```r
# tmp table
sql = "create table bioqc_gpl_annot(gpl varchar2(10) primary key, has_annot number(1))"
dbSendUpdate(mydb, sql)
annot = read.table("db/data/gpl_annot.txt")
annot = cbind(annot, rep(1, length(annot)))
colnames(annot) = c("1", "2")
dbAppendDf("BIOQC_GPL_ANNOT", annot)
# update gpl from tmp table
sqlUpdateGpl = "
  update bioqc_gpl g
  set has_annot = (select has_annot from bioqc_gpl_annot a
                     where g.gpl = a.gpl)"
dbSendUpdate(mydb, sqlUpdateGpl)
# drop tmp table
sql = "drop table bioqc_gpl_annot"
dbSendUpdate(mydb, sql)
```

We compared the two approaches in [Sample Selection](#sample-selection).

### Import summary statistics for each study

To perform a preliminary quality control on each study we calculated the min, max, median, mean and quartiles of the expression values of each study in GEO. This process is documented in [test_for_normalization.R](https://github.com/grst/BioQC_GEO_analysis/blob/master/scripts/test_for_normalization.R) and the project's [Makefile](https://github.com/grst/BioQC_GEO_analysis/blob/master/Makefile). We import the results into the database:


```r
study_stats = data.table(read_tsv(file.path(DATA_DIR, "gse_tissue_annot/study_stats.txt")))
study_stats = study_stats[,GSE:=sapply(as.character(study_stats[[1]]), geoIdFromPath)]
study_stats = study_stats[,GPL:=lapply(as.character(study_stats[[1]]), gplFromPath)]
setcolorder(study_stats, c(8, 9, 1:7))
study_stats[, 'filename'] = NULL # remove file name

dbSendUpdate(mydb, "truncate table bioqc_tmp_gse_gpl")
dbAppendDf("BIOQC_TMP_GSE_GPL", study_stats)
dbSendUpdate(mydb, "update bioqc_gse_gpl a
              set (study_mean, study_min, study_25, study_median, study_75, study_max) = (select study_mean, study_min, study_25, study_median, study_75, study_max from bioqc_tmp_gse_gpl b where a.gse = b.gse and (a.gpl = b.gpl or b.gpl is NULL))")
```

## Import BioQC data
We install the BioQC schema using this [SQL script](https://github.com/grst/BioQC_GEO_analysis/blob/master/db/bioqc_schema.sql).

### Signatures

Import signatures into the database and create a single, consolidated gmt file.

```r
# Signatures shipped with BioQC (updated version from 2016-12-08)
# download.file("http://bioinfo.bas.roche.com:8080/apps/gsea/genesets/exp.tissuemark.bioqc.roche.symbols.gmt",
#              "data/expr.tissuemark.affy.roche.symbols.gmt")
gmt2db(file.path(DATA_DIR, "expr.tissuemark.affy.roche.symbols.gmt"))

# control signatures generated from GTEx using *pygenesig*
gmt2db("../pygenesig-example/results/gtex_v6_gini_0.8_3/signatures.gmt", source='gtex_v6_gini.gmt')
gmt2db("../pygenesig-example/results/gtex_v6_solid_gini_0.8_1/signatures.gmt", source='gtex_v6_gini_solid.gmt')


# baseline signatures (random/housekeeping)
gmt2db("../pygenesig-example/results/baseline_signatures.gmt")

# pathway gene sets not relevant for this study
# gmt2db("../BioQC_correlated-pathways/go.bp.roche.symbols.gmt.uniq")
# gmt2db("../BioQC_correlated-pathways/MetaBase.downstream.expression.gmt")
# gmt2db("../BioQC_correlated-pathways/path.ronet.roche.symbols.gmt.ascii")

# save imported signatures to consolidated gmt file
db2gmt("results/gmt_all.gmt")
```


### Tissue Annotation

Import the [manually curated tissues](https://github.com/grst/BioQC_GEO_analysis/blob/master/manual_annotation/normalize_tissues.xlsx) from Excel into the database.

```r
normalized_tissues = data.table(read_excel("manual_annotation/tissue_annotation.xlsx", sheet = 1))
tissues = unique(normalized_tissues[!is.na(TISSUE_NORMALIZED),"TISSUE_NORMALIZED", with=FALSE])
tab_normalized = normalized_tissues[!is.na(TISSUE_NORMALIZED),c("TISSUE", "TISSUE_NORMALIZED"), with=FALSE]

dbAppendDf("BIOQC_TISSUES", tissues)
dbAppendDf("BIOQC_NORMALIZE_TISSUES", tab_normalized)
```

### Tissue Sets

Import the [manually curated tissue sets](https://github.com/grst/BioQC_GEO_analysis/blob/master/manual_annotation/tissue_sets.xlsx) from Excel into the database.

```r
bioqc_all = read_excel("manual_annotation/tissue_annotation.xlsx", sheet = 3)
gtex_all = read_excel("manual_annotation/tissue_annotation.xlsx", sheet = 4)
gtex_solid = read_excel("manual_annotation/tissue_annotation.xlsx", sheet = 5)
bioqc_solid = read_excel("manual_annotation/tissue_annotation.xlsx", sheet = 6)

signatureset2db(bioqc_all, "bioqc_all")
signatureset2db(gtex_solid, "gtex_solid")
signatureset2db(gtex_all, "gtex_all")
signatureset2db(bioqc_solid, "bioqc_solid")
```

### BioQC results {#import-bioqc-results}
Once we [ran the analysis](#sample-processing), we manually import the list of samples on which we successfully applied BioQC and the respective p-values into the tables **BIOQC_BIOQC_SUCCESS** and **BIOQC_RES**:

```
bioqc_melt_all.uniq.tsv
bioqc_success.txt
```

