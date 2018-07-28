# Curating Data {#curating-data}

## Selecting Samples by Metadata
[GEOmetadb](https://www.bioconductor.org/packages/release/bioc/vignettes/GEOmetadb/inst/doc/GEOmetadb.html) 
is a SQLite database containing metadata associated with samples and studies from GEO. This database has proven to be tremendously helpful for selecting samples by tissue and organism. We integrate the database into the [study's DBS](#setup-database) and describe how we select samples in detail in [sample selection](#sample-selection). 

## Normalize Tissues {#normalize-tissues}
The annotation of tissues is inconsistent within GEO. A "liver" sample can be termed *e.g.* "liver", "liver biopsy" or "primary liver". We therefore need a way to *normalize* the tissue name. We did this manually for the most abundant tissues in this [Excel sheet](https://github.com/grst/BioQC_GEO_analysis/blob/master/manual_annotation/tissue_annotation.xlsx). 

## Map tissues to signatures {#tissue-signatures} 
In order to find out which samples show *tissue heterogeniety*, we first need to define which signatures we would 'expect' in a certain tissue. We therefore manually mapped signatures to the respective tissue type in this 
[Excel sheet](https://github.com/grst/BioQC_GEO_analysis/blob/master/manual_annotation/tissue_annotation.xlsx). For example, we map the signatures `Intestine_Colon_cecum_NR_0.7_3` and `Intestine_Colon_NR_0.7_3` to *colon*.  

We mapped all *normalized tissues* from above to the respective signatures, which have at least 500 samples. We mapped tissues with a lower sample count only if they formed a subset of an already mapped tissue (*e.g.* we mapped *prefrontal cortex* to brain although having less than 500 samples, because we already mapped signatures to *brain*.)

Moreover, we ran into the issue, that some tissue signatures are not as specific as the annotation in the GEO. We therefore curated so-called *tissue sets* to combine them into groups. For example, it is hard to distinguish *jejunum* from *colon*, but easy to distinguish the two from other tissues. We therefore created a tissue set *intestine*, which contains both *jejunum* and *colon* and references all signatures associated with the two tissues. This information is part of the same [Excel sheet](https://github.com/grst/BioQC_GEO_analysis/blob/master/manual_annotation/tissue_annotation.xlsx).

We created a tissue set `bioqc_all` which maps all tissues to all signatures provided by the authors of *BioQC* and a high-confidence tissue-set `gtex_solid` which only maps tissues to signatures that we could validate as high-confidence signatures in [Validate Tissue Signatures](#validating-signatures). 
