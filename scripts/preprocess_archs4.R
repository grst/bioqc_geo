library(dplyr)
library(tidyr)
library(tibble)
library(readr)

# Independent Validation with NGS data (ARCHS4)
## We perform the same analysis with expression data from ARCHS4.

## Prepare that data.
## Make the data look the same like the dumps from the oracle database.
meta = bind_rows(read_tsv("./data/archs4/archs4_meta_human.tsv"), read_tsv("./data/archs4/archs4_meta_mouse.tsv")) %>%
  select(GSM, GPL, TISSUE_ORIG=source_name_ch1, TISSUE, TGROUP, TISSUE_SET)


pvalues = read_tsv("./data/archs4/bioqc_res_all.tsv") %>%
  select(SIGNATURE=signature, GSM, PVALUE=pvalue)

write_csv(meta, "./results/archs4/archs4_meta.csv")
write_csv(pvalues, "./results/archs4/archs4_res.csv")

