# BioQC GEO Analysis

Systematically testing the GEO for *tissue heterogeneity*. 

*Manuscript in preparation*

## Introduction
Recently we created a software tool, [*BioQC*](https://accio.github.io/BioQC), that detects tissue heterogeneity in gene expression data and shared it with the community of genome researchers via Bioconductor. The concept of tissue heterogeneity stems from our observations that gene expression data is often compromised by cells originating from other tissues than the target tissue of profiling. Tissue heterogeneity can be caused by physiological or pathological processes, such as immune cell infiltration. Alternatively, they can be caused by technical imperfection to separate complex or nearby tissues or even human errors. Failures in detecting tissue heterogeneity may have profound implications on data interpretation and reproducibility. 

As bioinformaticians working on drug discovery in the pharma industry, we are convinced that gene expression data available in publicly available databases such as NCBI Gene Expression Omnibus (GEO) or EBI ArrayExpress has great potential to catalyse new therapeutic agents. Disease signatures derived from disease models or patient biopsies, for instance, can be used to assess cellular models used for discovery and to guide compound selection. Molecular phenotypes of compounds, in another example, can be used to validate both efficacy and pre-clinical safety of compounds. Apparently all such applications depend critically on the quality of gene expression data. Several groups have scrutinised publicly available datasets and have identified deleterious factors of data quality such as batch effects, human error, and even data manipulation and faking. However, tissue heterogeneity has not been explicitly addressed so far and there is neither data nor knowledge about its prevalence. To fill this gap, we undertake a systematic investigation of publicly available gene expression datasets.

## The Experiment in Brief

[BioQC](https://accio.gitub.io/BioQC) implements a computationally efficient Wilcoxon-Mann-Whitney (WMW)-test which is applied to gene expression data on a sample-by-sample basis. Using BioQC, we can efficiently test for the enrichment of certain gene sets, or in this case *tissue signatures*. A tissue signature is a list of genes, which are predominantly expressed in a certain tissue. If the WMW-test shows a significant enrichment of a signature, we can conclude that the respective tissue is present in the sample. 

The authors of BioQC provide a list of more than 150 such signatures for a variety of tissues and cell types. For this study, we independently created and validated tissue signatures based on the [GTEx](http://gtexportal.org) dataset using [pygenesig](https://grst.github.io/pygenesig) as described in [Validating Signatures](#validating-signatures). 

We downloaded gene expression data from GEO using [GEOquery](https://bioconductor.org/packages/release/bioc/html/GEOquery.html) and obtained the associated metadata from [GEOmetadb](https://www.bioconductor.org/packages/release/bioc/html/GEOmetadb.html). Using the metadata, we selected samples as described in [sample selection](#sample-selection). On all all these samples, we applied BioQC to obtain a p-value for each tissue signature and stored them alongside with the metadata in a database system (DBS). The process of setting up the database is described in [Database Design](#setup-database). 

Finally, we identified contaminated samples from the signature scores. If a signature, which is not associated with the annotated tissue of origin, scores high, we assume the sample being heterogenous. In section [Tissue Migration](#tissue-migration), we describe how we identify contaminated samples and discuss common pattern of tissue heterogenity. 




