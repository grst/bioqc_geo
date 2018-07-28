--------------------------------------------------------------------------------
-- BIOQC_SELECTED_SAMPLES_TSET
-- 
-- add expected signatures to selected samples
--------------------------------------------------------------------------------
drop materialized view bioqc_selected_samples_tset;
create materialized view bioqc_selected_samples_tset
parallel 16
build immediate
refresh force
on demand
as 
  with bsst_pre as (
    select /*+ parallel(16) */  distinct bss.gsm
                                 , bss.gpl
                                 , bts.tissue
                                 , bts.tissue_set
                                 , bts.tgroup
                                 , bts2.signature as min_exp_sig
                                 , bs.name as min_exp_sig_name
                                 , br.pvalue as min_exp_pvalue
                                 , ROW_NUMBER() over (
                               partition by bss.gsm, bts.tissue, bts.tissue_set, bts.tgroup
                               order by min(br.pvalue) asc)
                               as rk
      from bioqc_selected_samples bss
      -- add tgroup to sample
      join bioqc_tissue_set bts
        on bts.tissue = bss.tissue
      -- add exp_signature to tgroup
      join bioqc_tissue_set bts2
        on bts2.tgroup = bts.tgroup
        and bts2.tissue_set = bts.tissue_set
      join bioqc_signatures bs
        on bs.id = bts2.signature
      left outer join bioqc_res br 
        on br.gsm = bss.gsm 
        and br.signature = bts2.signature
  --    where bts.tissue_set = 'gtex_all'
  --    and bts.tgroup = 'adipose'    
      group by bss.gsm, bss.gpl, bts.tissue, bts.tissue_set, bts.tgroup, bts2.signature, bs.name, br.pvalue
  ) 
  select gsm
       , gpl 
       , tissue
       , tissue_set
       , tgroup
       , min_exp_sig
       , min_exp_sig_name
       , min_exp_pvalue
  from bsst_pre
  where rk = 1;
create /*+ parallel(16) */ index bioqc_sst_gsm
  on bioqc_selected_samples_tset(gsm); 
create /*+ parallel(16) */ bitmap index bioqc_sst_tgroup
  on bioqc_selected_samples_tset(tgroup);
create /*+ parallel(16) */ index bioqc_sst_signature
  on bioqc_selected_samples_tset(min_exp_sig);
create /*+ parallel(16) */ bitmap index bioqc_sst_tissue_set
  on bioqc_selected_samples_tset(tissue_set);


--------------------------------------------------------------------------------
-- BIOQC_RES_TSET
--
-- add tissue groups to bioqc results (pvalues)
--------------------------------------------------------------------------------

drop materialized view bioqc_res_tset;
create materialized view bioqc_res_tset
parallel 16
build immediate
refresh force
on demand
as 
   with brt_pre as (
     select /*+ parallel(16) */ br.gsm
                              , br.signature as min_found_sig
                              , br.pvalue as min_found_pvalue
                              , bs.name as min_found_sig_name
                              , bts.tgroup as found_tgroup
                              , bts.tissue_set
                              , ROW_NUMBER() over (
                             partition by br.gsm, bts.tissue_set, bts.tgroup
                             order by min(br.pvalue) asc)
                             as rk
      from bioqc_res br
      -- we can reduce the amount of data by only keeping values of selected samples
      join bioqc_selected_samples bss
        on bss.gsm = br.gsm
      join bioqc_signatures bs
        on br.signature = bs.id
      join bioqc_tissue_set bts
        on bts.signature = br.signature
  --    where bts.tissue_set = 'gtex_all'
  --    and bts.tgroup = 'adipose' 
      group by br.gsm, br.signature, br.pvalue, bs.name, bts.tgroup, bts.tissue_set
  ) 
  select gsm
       , min_found_sig
       , min_found_pvalue
       , min_found_sig_name
       , found_tgroup
       , tissue_set
  from brt_pre
  where rk = 1;
create /*+ parallel(16) */ index bioqc_rt_gsm
  on bioqc_res_tset(gsm); 
create /*+ parallel(16) */ index bioqc_rt_found_sig
  on bioqc_res_tset(min_found_sig);
create /*+ parallel(16) */ bitmap index bioqc_rt_found_tgroup
  on bioqc_res_tset(found_tgroup);
create /*+ parallel(16) */ bitmap index bioqc_rt_tissue_set
  on bioqc_res_tset(tissue_set);
  
create or replace view bioqc_contamination
as 
  select /*+ parallel(16) */ bsst.gsm
                           , bsst.gpl 
                           , bsst.tissue_set
                           , bsst.tgroup
                           , bsst.min_exp_sig
                           , bsst.min_exp_sig_name
                           , bsst.min_exp_pvalue
                           , brt.found_tgroup
                           , brt.min_found_sig
                           , brt.min_found_sig_name
                           , brt.min_found_pvalue
                           , bsst.tissue
                           , bss.organism
                           , bss.year
                           , bss.country
  from bioqc_selected_samples_tset bsst
  join bioqc_res_tset brt 
    on bsst.gsm = brt.gsm
    and bsst.tissue_set = brt.tissue_set 
  join bioqc_selected_samples bss
    on bss.gsm = bsst.gsm;
  

create or replace view bioqc_baseline
as
select tissue_set
     , gpl
     , tgroup
     , found_tgroup
     , count(gsm) cnt
     , median(min_found_pvalue) median
     , stddev(min_found_pvalue) stddev
     , avg(min_found_pvalue) avg
from BIOQC_CONTAMINATION
group by tissue_set, gpl, tgroup, found_tgroup
having count(gsm) >= 100;


drop materialized view contaminated_studies;
create materialized view contaminated_studies
parallel 16
build immediate
refresh force
on demand
as
  with gse_count as (
    select gse
         , count(gsm) as samples_in_study
    from bioqc_gse_gsm
    group by gse
  ),
  contam_samples as (
    select /*+ parallel(16) */ * 
    from bioqc_contamination bc
    where tissue_set = 'gtex_solid'
    and min_found_pvalue < 0.0001
    and tgroup != found_tgroup
    and not (
      (tgroup = 'heart' and found_tgroup = 'skeletal muscle') or
      (tgroup = 'skeletal muscle' and found_tgroup = 'heart'))
  ),
  contam_studies as (
    select bgg.gse
          , cs.tgroup
          , cs.found_tgroup
          , count(cs.gsm) as contaminated_samples
    from contam_samples cs
    join bioqc_gse_gsm bgg
      on bgg.gsm = cs.gsm 
    group by bgg.gse, cs.tgroup, cs.found_tgroup
  )
  select /*+ parallel(16) */ cs.gse
                           , cs.tgroup as expected_tissue
                           , cs.found_tgroup as found_tissue
                           , cs.contaminated_samples
                           , gc.samples_in_study
                           , bge.title
                           , bge.status
                           , bge.submission_date
                           , bge.last_update_date
                           , bge.summary
                           , bge.pubmed_id
                           , bge.contributor
                           , bge.overall_design
                           , bge.contact
  from contam_studies cs
  join gse_count gc
    on gc.gse = cs.gse
  join bioqc_gse bge
    on bge.gse = cs.gse
  order by cs.tgroup, cs.found_tgroup, cs.contaminated_samples desc;

