--------------------------------------------------------------------------------
-- A list of all original tissue annotations
-- occuring in udis and GEO. 
--
-- Export this to the excel sheet for manual annotation
--------------------------------------------------------------------------------

create materialized view bioqc_all_tissues
build immediate
refresh force
on demand
as 
  with all_tissues as (
    select /*+ parallel(16) */  lower(tissue_orig) as tissue
                              , gsm as study_id
    from bioqc_gsm
    where tissue_orig is not null
    union 
    select /*+ parallel(16) */ lower(tissue_or_cell_type) as tissue
                             , cast(experiment_name as varchar(15)) as study_id
    from udis_meta
    where tissue_or_cell_type is not null
  )
  select /*+ parallel(16) */ tissue, count(study_id) as cnt
  from all_tissues
  group by tissue
  order by cnt desc;