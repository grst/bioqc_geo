alter table udis_meta
add primary key (experiment_name);

create table  udis_res(experiment_name number(10) not null 
                     , signature number(10) not null
                     , pvalue binary_double
                     , primary key(experiment_name, signature)
                     , foreign key(experiment_name)
                        references udis_meta(experiment_name)
                     , constraint fk_udis_res_signature
                        foreign key (signature)
                        references bioqc_signatures(id)
) tablespace srslight_d;

