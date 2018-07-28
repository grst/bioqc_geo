-- alter table bioqc_gsm add column tissue_orig
create index /*+ parallel(16) */ bioqc_gsm_tissue_orig
  on bioqc_gsm(lower(tissue_orig));

-- Table Tissues: holds manually selected tissues 
create table bioqc_tissues(id varchar2(80) not null primary key) 
  tablespace srslight_d;
  
-- map hetergenous tissue annotation from geo to unified tissue name 
create table bioqc_normalize_tissues(tissue_orig varchar(1000) not null primary key
                                   , tissue varchar(80) not null 
                                       references bioqc_tissues(id))
  tablespace srslight_d;
create index bioqc_nt_tissue on bioqc_normalize_tissues(tissue);
  

create table bioqc_signatures(id number(10) not null primary key
                            , name varchar2(255) not null          -- name of the signature in gmt
                            , source varchar2(255) not null        -- gmt filename
                            , description clob null                -- description in gmt
                            , gene_symbols clob null               -- comma separated list of gene symbols in gmt
                            , constraint bioqc_uq_signatures
                                unique(name, source)
) tablespace srslight_d;

create index bioqc_signatures_source on bioqc_signatures(source);


-- TEST_EXCLUDE_START (this statement won't be used in the test database)
-- auto increment for bioqc_signatures
create sequence bioqc_sig_seq start with 1;

create or replace trigger bioqc_sig_bir
before insert on bioqc_signatures
for each row
begin 
  select sig_seq.NEXTVAL
  into :new.id
  from dual;
end;
-- TEST_EXCLUDE_END

create table bioqc_tissue_set( signature number(10) not null 
                                    references bioqc_signatures(id)
                                , tissue varchar2(80) not null
                                    references bioqc_tissues(id)
                                , tgroup varchar(80) not null
                                , tissue_set varchar(80) not null                  
                                , primary key(signature, tissue, tissue_set)
    
) tablespace srslight_d;
create bitmap index bioqc_ts_tgroup on bioqc_tissue_set(tgroup); 
create bitmap index bioqc_ts_tissue_set on bioqc_tissue_set(tissue_set); 
create index bioqc_ts_tissue on bioqc_tissue_set(tissue); 
create index bioqc_ts_signature on bioqc_tissue_set(signature); 
create bitmap index bioqc_ts_tgts on bioqc_tissue_set(tgroup, tissue_set); 

-- for inserting tissue sets 
create global temporary table bioqc_tmp_tissue_set (
    signature_name varchar2(255) not null 
  , signature_source varchar2(255) not null
  , tgroup varchar(80) not null
  , tissue varchar(80) not null
  , tissue_set varchar(80) not null
) on commit preserve rows;

CREATE global temporary TABLE bioqc_tmp_gse_gpl 
( gse varchar2(15),
	gpl varchar2(15),
  study_mean float, 
  study_min float,
  study_25 float,
  study_median float, 
  study_75 float,
  study_max float
) on commit preserve rows;

create index bioqc_gse_gpl_iqr on bioqc_gse_gpl(abs(study_75 - study_25)); 

create table bioqc_res(gsm varchar2(10) not null 
                        references bioqc_gsm(gsm)
                     , signature number(10) not null
                        references bioqc_signatures(id)
                        on delete cascade
                     , pvalue binary_double
                     , primary key(gsm, signature)
) tablespace srslight_d;

-- contain all samples on which we successfully ran bioqc.
-- serves as background for contamination analysis
create table bioqc_bioqc_success(gsm varchar2(10) not null references bioqc_gsm(gsm) primary key);

