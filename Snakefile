from snakemake.remote.HTTP import RemoteProvider as HTTPRemoteProvider
HTTP = HTTPRemoteProvider()

RMD_FILES, = glob_wildcards("notebooks/{rmd_files}.Rmd")

# all files in the data directory
DATA_FILES = [
  "data/bioqc_geo_oracle_dump/BIOQC_SIGNATURES_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_TMP_TISSUE_SET_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_NORMALIZE_TISSUES_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/materialized_views/CONTAMINATED_STUDIES_DATA_MATERIALIZED VIEW.csv",
  "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_STUDIES_HAS_ANNOT_DATA_MATERIALIZED VIEW.csv",
  "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_STUDIES_HAS_PACKAGE_DATA_MATERIALIZED VIEW.csv",
  "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_STUDIES_HAS_TISSUE_DATA_MATERIALIZED VIEW.csv",
  "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_SELECTED_SAMPLES_TSET_DATA_MATERIALIZED VIEW.csv",
  "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_ALL_TISSUES_DATA_MATERIALIZED VIEW.csv",
  "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_SELECTED_SAMPLES_DATA_MATERIALIZED VIEW.csv",
  "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_RES_TSET_DATA_MATERIALIZED VIEW.csv",
  "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_STUDIES_TOTAL_DATA_MATERIALIZED VIEW.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_GSE_GSM_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_GSM_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_SMATRIX_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_SIGNALS_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_GEODB_COLUMN_DESC_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_BIOQC_SUCCESS_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_RES_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_GPL_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_METAINFO_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_GSE_GPL_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_GEOCONVERT_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_TISSUES_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_GDS_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_GSE_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/views/BIOQC_TISSUE_MIGRATION_DATA_VIEW.csv",
  "data/bioqc_geo_oracle_dump/views/BIOQC_BASELINE_DATA_VIEW.csv",
  "data/bioqc_geo_oracle_dump/views/BIOQC_CONTAM_STATS_DATA_VIEW.csv",
  "data/bioqc_geo_oracle_dump/views/BIOQC_GSM_TISSUE_DATA_VIEW.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_GDS_SUBSET_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_TMP_GSE_GPL_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_SIGNATURE_SYMBOL_DATA_TABLE.csv",
  "data/bioqc_geo_oracle_dump/BIOQC_TISSUE_SET_DATA_TABLE.csv",
  "data/paxdb/Jitao David Zhang - PAXDB-humanGregorGEOBioQC-cache.RData",
  "data/paxdb/Jitao David Zhang - PAXDB-humanEset-phenoData.txt",
  "data/paxdb/Jitao David Zhang - PAXDB-mouseGregorGEOBioQC-cache.RData",
  "data/paxdb/Jitao David Zhang - PAXDB-mouseEset-phenoData.txt",
  "data/archs4/Jitao David Zhang - ARCHS4-mouseGregorGEOBioQC-cache.RData",
  "data/archs4/Jitao David Zhang - ARCHS4-humanEset-phenoData.txt",
  "data/archs4/Jitao David Zhang - ARCHS4-humanGregorGEOBioQC-cache.RData",
  "data/archs4/Jitao David Zhang - ARCHS4-mouseEset-phenoData.txt"
]


rule book:
  """build book using R bookdown"""
  input:
    # data
    # DATA_FILES,
    # preprocessed files
    "results/data_processed.RData",
    "results/archs4/archs4_data_processed.RData",
    "results/models.RData",
    "results/archs4/archs4_models.RData",
    # content (Rmd files and related stuff)
    expand("notebooks/{rmd_files}.Rmd", rmd_files = RMD_FILES),
    "notebooks/bibliography.bib",
    "notebooks/_bookdown.yml",
    "notebooks/_output.yml",
    "notebooks/config.R"
  output:
    "results/book/index.html",
    "results/figures/scores_geo.png",
    "results/figures/scores_archs4.png",
    "results/figures/correlations_geo.png",
    "results/figures/correlations_archs4.png",
    "results/figures/heterogeneity_main_res.pdf",
    "results/figures/heterogeneity_fractions.pdf",
  conda:
    "envs/bookdown.yml"
  shell:
    "cd notebooks && "
    "Rscript -e \"bookdown::render_book('index.Rmd')\""


rule data:
   """download data from archive"""
   input:
     # TODO change to github once published
     HTTP.remote("www.cip.ifi.lmu.de/~sturmg/bioqc/data.tar.gz", allow_redirects=True)
   output:
     DATA_FILES
   shell:
     "mkdir -p data && "
     "tar -xvzf {input} -C data --strip-components 1"


rule preprocess_archs:
    """preprocess archs4 data to be in a consisten format with
    the GEO data"""
    input:
      "scripts/preprocess_archs4.R",
      "data/bioqc_geo_oracle_dump/BIOQC_GSM_DATA_TABLE.csv",
      "data/bioqc_geo_oracle_dump/BIOQC_NORMALIZE_TISSUES_DATA_TABLE.csv",
      "data/bioqc_geo_oracle_dump/BIOQC_TISSUE_SET_DATA_TABLE.csv",
      "data/archs4/Jitao David Zhang - ARCHS4-humanGregorGEOBioQC-cache.RData",
      "data/archs4/Jitao David Zhang - ARCHS4-mouseGregorGEOBioQC-cache.RData",
      "data/archs4/Jitao David Zhang - ARCHS4-humanEset-phenoData.txt",
      "data/archs4/Jitao David Zhang - ARCHS4-mouseEset-phenoData.txt"
    output:
      "results/archs4/archs4_res.csv",
      "results/archs4/archs4_meta.csv"
    conda:
      "envs/preprocess_archs.yml"
    shell:
      "Rscript scripts/preprocess_archs4.R"


rule process_geo:
  """processes BioQC results into a set of R-objects
  that can be readliy used for analysis"""
  input:
    "scripts/process_data.R",
    "data/bioqc_geo_oracle_dump/BIOQC_RES_DATA_TABLE.csv",
    "data/bioqc_geo_oracle_dump/materialized_views/BIOQC_SELECTED_SAMPLES_TSET_DATA_MATERIALIZED VIEW.csv"
  output:
    "results/data_processed.RData"
  conda:
    "envs/process_bioqc.yml"
  shell:
    "Rscript {input:q} {output:q}"


rule process_archs:
  """processes BioQC results into a set of R-objects
  that can be readliy used for analysis"""
  input:
    "scripts/process_data.R",
    "results/archs4/archs4_res.csv",
    "results/archs4/archs4_meta.csv"
  output:
    "results/archs4/archs4_data_processed.RData"
  conda:
    "envs/process_bioqc.yml"
  shell:
    "Rscript {input:q} {output:q}"


rule model_geo:
  """correct for correlation of the signatures by fitting `rlm` models. """
  input:
    "scripts/correct_for_correlation.R",
    "results/data_processed.RData",
  output:
    "results/models.RData"
  conda:
    "envs/model_correlation.yml"
  threads: 8
  shell:
    "Rscript {input:q} {output:q}"


rule model_archs:
  """correct for correlation of the signatures by fitting `rlm` models. """
  input:
    "scripts/correct_for_correlation.R",
    "results/archs4/archs4_data_processed.RData",
  output:
    "results/archs4/archs4_models.RData"
  conda:
    "envs/model_correlation.yml"
  threads: 8
  shell:
    "Rscript {input:q} {output:q}"




rule upload_book:
  """publish the book on github pages"""
  input:
    "results/book/index.html"
  shell:
    """
    cd gh-pages && \
    cp -R ../results/book/* ./ && \
    git add --all * && \
    git commit --allow-empty -m "update docs" && \
    git push origin gh-pages
    """


rule clean:
  """remove figures and the HTML report. """
  run:
    _clean()


rule wipe:
  """remove all results, including all caches. """
  run:
    _wipe()


rule _data_archive:
    """
    FOR DEVELOPMENT ONLY.

    Generate a data.tar.gz archive from data.in to publish on github.
    """
    input:
      "data.in"
    output:
      "results/data.tar.gz"
    shell:
      "tar cvzf {output} data.in"


def _clean():
  shell(
    """
    rm -rfv results/book/*
    rm -rfv notebooks/_bookdown_files/*files
    rm -fv notebooks/_main*
    rm -fv notebooks/*.md
    """)


rule _wipe_bookdown:
  """wipe bookdown cache only, keep expensive sensitivity/specificity caches. """
  run:
    _wipe_bookdown()


def _wipe():
  _clean()
  shell(
    """
    rm -rfv notebooks/_bookdown_files
    rm -rfv results
    """)

def _wipe_bookdown():
  _clean()
  shell(
    """
    rm -rfv notebooks/_bookdown_files
    """)
