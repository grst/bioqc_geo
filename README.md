# Tissue heterogeneity is prevalent in gene expression studies


> Gregor Sturm, Markus List and Jitao David Zhang. Tissue heterogeneity is prevalent in gene expression studies

The source code in this project can be used to reproduce the results
described in the paper. 

Running the pipeline will generate the figures and supplementary information from the paper. 
The supplementary information is additionally available as a website on 
[grst.github.io/bioqc_geo](https://grst.github.io/bioqc_geo). 

## Running the pipeline
Short version:
```
conda install snakemake
git clone git@github.com:grst/bioqc_geo.git
cd bioqc_geo
snakemake --use-conda
```

For details, see below.

### Prerequisites
This pipeline uses [conda](https://conda.io/miniconda.html) to install all dependencies and
[Snakemake](https://snakemake.readthedocs.io/en/stable/) to orchestrate the analyses.

1. **Download and install [Miniconda](https://conda.io/miniconda.html)**
2. **Install snakemake**
```
conda install snakemake
```

3. **Clone this repo.** We use a [git submodule](https://git-scm.com/docs/git-submodule) to import
the source code for the [immundeconv](https://github.com/grst/immunedeconv) R package.
```
git clone git@github.com:grst/bioqc_geo.git
```

### Run the pipeline
To perform all computations and to generate a HTML report with
[bookdown](https://bookdown.org/yihui/bookdown/) invoke
the corresponding `Snakemake` target:

```
snakemake --use-conda book
```

Make sure to use the `--use-conda` flag to tell Snakemake to download all dependencies from Anaconda.org.

The pipeline will generate a `results` folder which will contain
the rendered supplementary information as PDF and HTML documents, 
the figures a detailed result file with heterogeneity results
for all tested samples. 


### Performance and caching
Building the entire project can take a long time (multiple hours).
You can speed up the build process by enabling parallel processing:

```
snakemake --use-conda --cores 16
```

Up to 16 cores will lead to a speedup, most of the pipeline is sequential,
though.

**Memory requirements**: You need about 4GB of memory per core and at least
16GB of total memory to run the pipeline.

To speed up repetitive builds, `bookdown` will automatically create caches.
To remove all caches and results, use `snakemake wipe`.

### Useful Snakemake targets
Have a look at the `Snakefile`, it is self-explanatory.

A list of the most useful targets
```
snakemake --use-conda book       # generate a HTML-book in `results/book`
snakemake --use conda            # default target (= book)
snakemake clean                  # cleans the HTML book
snakemake wipe                   # cleans everything, including all caches.
```

### Preprocessed data
This pipeline makes use of preprocesse BioQC results.
Downloading the entire GEO and running BioQC on all samples
takes a lot of computational resources. Therefore,
we provide pre-calculated intermediate results, that
are used by this pipeline.

If you are interested in reproducing these files and
building the BioQC-GEO database from scratch, hava a look
at [grst/BioQC_GEO_analysis](https://github.com/grst/BioQC_GEO_analysis).
