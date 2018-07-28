------------------------------------------------------
-- create views to easily access samples/studies
-- that have: 
--   * tissue annotated
--   * a bioconductor package to annotate gene names
--   * a GEO GPL annotation file to annotate gene names
------------------------------------------------------

create materialized view bioqc_studies_total
parallel 16
build immediate
refresh force
on demand
as 
  select /*+ parallel(16) */  bioqc_gsm.gsm
                            , bioqc_gse_gsm.gse
  from bioqc_gsm
  join bioqc_gse_gsm on bioqc_gse_gsm.gsm = bioqc_gsm.gsm;

create materialized view bioqc_studies_has_tissue
parallel 16
build immediate
refresh force
on demand
as 
  select /*+ parallel(16) */  bioqc_gsm.gsm
                            , bioqc_gse_gsm.gse 
  from bioqc_gsm
  join bioqc_gse_gsm on bioqc_gse_gsm.gsm = bioqc_gsm.gsm
  where tissue is not NULL and tissue != 'other';

create materialized view bioqc_studies_has_package
parallel 16
build immediate
refresh force
on demand
as 
  select /*+ parallel(16) */  bioqc_gsm.gsm
                            , bioqc_gse_gsm.gse
  from bioqc_gsm
  join bioqc_gse_gsm on bioqc_gse_gsm.gsm = bioqc_gsm.gsm
  join bioqc_gpl on bioqc_gpl.gpl = bioqc_gsm.gpl
  where bioqc_gpl.bioc_package is not NULL;

create materialized view bioqc_studies_has_annot
parallel 16
build immediate
refresh force
on demand
as 
  select /*+ parallel(16) */  bioqc_gsm.gsm
                            , bioqc_gse_gsm.gse 
  from bioqc_gsm
  join bioqc_gse_gsm on bioqc_gse_gsm.gsm = bioqc_gsm.gsm
  where gpl in (
    select distinct gpl
    from bioqc_gpl
    where has_annot = 1
  );
