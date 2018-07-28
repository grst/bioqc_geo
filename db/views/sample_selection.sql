--------------------------------------------------------------------------------
-- BIOQC_SELECTED_SAMPLES
--
-- "background" 
--------------------------------------------------------------------------------

drop materialized view bioqc_selected_samples;
create materialized view bioqc_selected_samples
parallel 16
build immediate
refresh force
on demand
as 
  select /*+ parallel(16) */ distinct bg.gsm
                           , bg.gpl
                           , bg.organism_ch1 as organism
                           , bg.tissue_orig
                           , bnt.tissue
                           , cast(
                               cast(
                                 regexp_substr(submission_date, '^(\d{4})-.*', 1, 1, NULL, 1) 
                                 as varchar2(4)
                               )
                               as NUMBER(4)
                             ) as year
                           , cast(
                               TRIM(BOTH from
                                    regexp_substr(contact, 'Country:(.*?)(;.*)?$', 1, 1, NULL, 1) 
                               )
                               as varchar2(100)
                             ) as country
  from bioqc_bioqc_success bs
  join bioqc_gsm bg
    on bg.gsm = bs.gsm
  join bioqc_gse_gsm bgg
    on bgg.gsm = bs.gsm 
  join bioqc_normalize_tissues bnt
    on bnt.tissue_orig = lower(bg.tissue_orig)
  join bioqc_gse_gpl bgl
    on bgg.gse = bgl.gse
    and bg.gpl = bgl.gpl
  join bioqc_res br
    on br.gsm = bg.gsm
  where channel_count = 1
  and organism_ch1 in ('Homo sapiens', 'Mus musculus', 'Rattus norvegicus')
  and ABS(study_75 - study_25) >= .5 -- IQR to ensure sufficient variance. 
  and signature = 56184 --awesome housekeepers
  and pvalue < 1e-5;
  
create /*+ parallel(16) */ index bss_gsm
  on bioqc_selected_samples(gsm); 
create /*+ parallel(16) */ bitmap index bss_tissue
  on bioqc_selected_samples(tissue);
create /*+ parallel(16) */ bitmap index bss_year
  on bioqc_selected_samples(year);
create /*+ parallel(16) */ bitmap index bss_country
  on bioqc_selected_samples(country);
create /*+ parallel(16) */ bitmap index bss_gpl
  on bioqc_selected_samples(gpl);
  
  
