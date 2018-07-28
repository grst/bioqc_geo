CREATE TABLE bioqc_gse
( ID NUMBER(10),
	title CLOB,
	gse varchar2(15) primary key,
	status CLOB,
	submission_date CLOB,
	last_update_date CLOB,
	pubmed_id NUMBER(10),
	summary CLOB,
	type CLOB,
	contributor CLOB,
	web_link CLOB,
	overall_design CLOB,
	repeats CLOB,
	repeats_sample_list CLOB,
	variable CLOB,
	variable_description CLOB,
	contact CLOB,
	supplementary_file CLOB 
) tablespace srslight_d;

CREATE TABLE bioqc_gpl 
( ID NUMBER(10),
	title CLOB,
	gpl varchar2(15) primary key,
	status CLOB,
	submission_date CLOB,
	last_update_date CLOB,
	technology CLOB,
	distribution CLOB,
	organism CLOB,
	manufacturer CLOB,
	manufacture_protocol CLOB,
	coating CLOB,
	catalog_number CLOB,
	support CLOB,
	description CLOB,
	web_link CLOB,
	contact CLOB,
	data_row_count NUMBER(10),
	supplementary_file CLOB,
	bioc_package CLOB 
) tablespace srslight_d;

CREATE TABLE bioqc_gsm 
( ID NUMBER(10),
	title CLOB,
	gsm varchar2(15) primary key,
	series_id CLOB,
	gpl varchar2(15),
	status varchar2(255),
	submission_date varchar2(10),
	last_update_date varchar2(10),
	type varchar(50),
	source_name_ch1 CLOB,
	organism_ch1 varchar(255),
	characteristics_ch1 CLOB,
	molecule_ch1 varchar(255),
	label_ch1 CLOB,
	treatment_protocol_ch1 CLOB,
	extract_protocol_ch1 CLOB,
	label_protocol_ch1 CLOB,
	source_name_ch2 CLOB,
	organism_ch2 CLOB,
	characteristics_ch2 CLOB,
	molecule_ch2 CLOB,
	label_ch2 CLOB,
	treatment_protocol_ch2 CLOB,
	extract_protocol_ch2 CLOB,
	label_protocol_ch2 CLOB,
	hyb_protocol CLOB,
	description CLOB,
	data_processing CLOB,
	contact CLOB,
	supplementary_file CLOB,
	data_row_count NUMBER(10),
	channel_count NUMBER(10) 
) tablespace srslight_d;

create index /*+ parallel(16) */ bioqc_gsm_organism_ch1 on bioqc_gsm(organism_ch1);

CREATE TABLE bioqc_gse_gsm 
( gse varchar2(15),
	gsm varchar2(15),
  primary key(gse, gsm)
) tablespace srslight_d;

CREATE TABLE bioqc_gse_gpl 
( gse varchar2(15),
	gpl varchar2(15),
  study_mean float, 
  study_min float,
  study_25 float,
  study_median float, 
  study_75 float,
  study_max float,
  primary key(gse, gpl)
) tablespace srslight_d;

CREATE TABLE bioqc_gds 
( ID NUMBER(10),
	gds varchar2(15) primary key,
	title CLOB,
	description CLOB,
	"TYPE" CLOB,
	pubmed_id CLOB,
	gpl varchar2(15),
	platform_organism CLOB,
	platform_technology_type CLOB,
	feature_count NUMBER(10),
	sample_organism CLOB,
	sample_type CLOB,
	channel_count CLOB,
	sample_count NUMBER(10),
	value_type CLOB,
	gse CLOB,
	"ORDER" CLOB,
	update_date CLOB 
) tablespace srslight_d;

CREATE TABLE bioqc_gds_subset 
( ID NUMBER(10),
	Name varchar2(1000) primary key,
	gds varchar2(15),
	description CLOB,
	sample_id CLOB,
	type CLOB 
) tablespace srslight_d;
CREATE TABLE bioqc_sMatrix 
( ID NUMBER(10),
	sMatrix varchar(1000) primary key,
	gse varchar2(15),
	gpl varchar2(15),
	GSM_Count NUMBER(10),
	Last_Update_Date CLOB 
) tablespace srslight_d;

CREATE TABLE bioqc_geodb_column_desc 
( TableName varchar(200),
	FieldName varchar(200),
	Description CLOB,
  primary key(TableName, FieldName)
) tablespace srslight_d;

CREATE TABLE bioqc_geoConvert(
  from_acc varchar2(1000),
  to_acc varchar2(1000),
  to_type CLOB,
  primary key(from_acc, to_acc)
) tablespace srslight_d;

CREATE TABLE bioqc_metaInfo (
  name varchar2(50) primary key,
  value varchar2(50)
) tablespace srslight_d;
