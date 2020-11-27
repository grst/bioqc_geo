---
output:
  pdf_document: default
bibliography: bibliography.bib
biblio-style: apalike
link-citations: yes
colorlinks: yes
---

# Sample data and metadata {#curating-data}

In this section, we describe how we obtained and curated gene expression data and sample metadata. 


## Standardize Tissue Names {#normalize-tissues}

The annotation of tissues is inconsistent within GEO and ARCHS4. A "liver" sample can be termed *e.g.* "liver", "liver biopsy" or "primary liver". We, therefore, need a way to *standardize* the tissue name. We manually mapped the most abundant tissues to a controlled vocabulary. Next, in order to find out which samples are subject to *tissue heterogeniety*, we first need to define which signatures we would expect in a certain tissue. For example, we map the signatures `Intestine_Colon_cecum_NR_0.7_3` and `Intestine_Colon_NR_0.7_3` to *colon*.
Since the reference signatures are not as specific as the annotation in GEO/ARCHS4, we created *tissue sets* to combine them into groups. For instance, it is hard to distinguish *jejunum* from *colon*, but easy to distinguish the two from other tissues. We therefore created a tissue set *intestine*, which contains both *jejunum* and *colon* and references all signatures associated with the two tissues. All of the described mappings are available from this [Excel sheet](https://github.com/grst/BioQC_GEO_analysis/blob/master/manual_annotation/tissue_annotation.xlsx) ^[https://github.com/grst/BioQC_GEO_analysis/blob/master/manual_annotation/tissue_annotation.xlsx].


## GEO

###  Downloading GEO data

We retrieved sample metadata for GEO using the [GEOmetadb](https://www.bioconductor.org/packages/release/bioc/vignettes/GEOmetadb/inst/doc/GEOmetadb.html) package [@geometadb]. 
We download the studies with [GEOquery](https://bioconductor.org/packages/release/bioc/html/GEOquery.html) [@geoquery] and store them as R [ExpressionSet](https://bioconductor.org/packages/devel/bioc/vignettes/Biobase/inst/doc/ExpressionSetIntroduction.pdf) [@Huber2015] using the R script [geo_to_eset.R](https://github.com/grst/BioQC_GEO_analysis/blob/master/scripts/geo_to_eset.R) ^[https://github.com/grst/BioQC_GEO_analysis/blob/master/scripts/geo_to_eset.R]. We used the `annotGPL=TRUE` option of GEOquery's `getGEO` function to obtain gene symbols for the studies, where available. 
Since the tissue signatures use human gene symbols, we added human orthologs for all mouse and rat samples using the [ribiosAnnotation](https://github.com/bedapub/ribiosUtils) ^[https://github.com/bedapub/ribiosUtils] package. 


###  Filtering GEO data

We filtered GEO samples by the following criteria (figure \@ref(fig:funnelgeo)): 

 1. the tissue or origin is annotated,
 2. gene symbols are annotated,
 3. the readout was performed on a single-channel microarray, and
 4. the tissue could be mapped to the controlled vocabulary (section \@ref(normalize-tissues)). 
 5. We only retained samples from the three major organisms: human, rat and mouse. 
 6. We removed studies which have been normalized per-gene and where ubiquitous house-keeping genes were not expressed. 
 7. Finally, we only retained samples originating from tissues for which a *reference signature* is available. 


\begin{figure}[h]

{\centering \includegraphics[width=0.4\linewidth]{../figures/funnel_geo} 

}

\caption{Summary of filtering steps on GEO samples}(\#fig:funnelgeo)
\end{figure}


## ARCHS4

In addition to GEO, we used data from
[ARCHS4](https://amp.pharm.mssm.edu/archs4/) [@Lachmann2018], a publicly available data
collection of annotaed, consistently processed gene expression datasets based
on RNA-sequencing. We downloaded gene expression and metadata as `RData` objects
from the [ARCHS4 website](https://amp.pharm.mssm.edu/archs4/download.html) (version 8.0) ^[https://amp.pharm.mssm.edu/archs4/download.html]. 

We filtered samples by the following criteria (figure \@ref(fig:funnelarchs)): 

1. The library is a transcriptomic cDNA library, the library strategy is RNA-seq, and either polyA or total RNA were extracted.
2. No single-cell RNA-seq samples (none of the annotation fields may contain the keywords "single-cell", "single cell" or "smartseq")
3. At least 500,000 reads could be mapped to genes. 
4. The tissue could be mapped to the controlled vocabulary (section \@ref(normalize-tissues)). 
5. Finally, we only retained samples originating from tissues for which a *reference signature* is available. 

Gene counts were normalized into TPM values before analysing them with BioQC. 


\begin{figure}[h]

{\centering \includegraphics[width=0.4\linewidth]{../figures/funnel_archs4} 

}

\caption{Summary of filtering steps on ARCHS4 samples}(\#fig:funnelarchs)
\end{figure}




