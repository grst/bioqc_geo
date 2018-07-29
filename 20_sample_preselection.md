# Sample Selection and processing {#sample-selection}

In this chapter, we document how

* we obtain samples from the Gene Expression Omnibus (GEO)
* we filter the samples according the the availability of attributes and
  certain quality criteria.





## Sample Preselection
Here, we document the sample selection process before running *BioQC*.

### Required annotation
A sample is *usable* for this study, if

* the gene symbos are annotated (requirement to run BioQC)
* the tissue of origin is annotated (requirment to draw conclusions about contamination)

We consider two approaches for annotating gene symbols:

* Using the Bioconductor [AnnotationDbi](https://bioconductor.org/packages/release/bioc/html/AnnotationDbi.html) package. The GEOmetadb provides a mapping of the GPL identifier to these packages.
* Using the `annotGPL=TRUE` option of [GEOquery](https://bioconductor.org/packages/release/bioc/html/GEOquery.html)'s `getGEO`. This requires an annotation file being available for the respective platform. We retrieved a list of the available annotation files [in an earlier step](#load-annotation-information).

We compare the two methods with respect to the amount of usable samples that we can get.

We create the 'annotation statistics' using an  [sql script](https://github.com/grst/BioQC_GEO_analysis/blob/master/db/views/annotation_stats.sql) and calculate these Venn diagrams:




<div class="figure">
<img src="20_sample_preselection_files/figure-html/sample-filtering2-1.png" alt="Venn diagrams comparing two different approaches for annotating gene symbols. The left and right diagram show the numbers of samples (GSM) and studies (GSE) respectively." width="672" />
<p class="caption">(\#fig:sample-filtering2)Venn diagrams comparing two different approaches for annotating gene symbols. The left and right diagram show the numbers of samples (GSM) and studies (GSE) respectively.</p>
</div>

The `getGEO` method appears to be the more powerful method. Ideal would be a combination of the two, however, for the sake of simplicity, we stick to `getGEO`, loosing 499 studies (35602 samples).

This leaves us with the following filtering result:

comment                           GSM     GSE
---------------------------  --------  ------
total                         1945417   73719
tissue annotated               760798   24267
annotation file available      768346   31579
tissue and annotation file     275206    9632
