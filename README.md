# A prevalence of tissue heterogeneity in gene expression studies

> Sturm, G and Zhang JD, *Manuscript in preparation* 

The source code in this project can be used to reproduce the results
described in the paper. 

Running the pipeline will generate an interactive HTML report using
[bookdown](https://bookdown.org/yihui/bookdown/), which is equivalent
to the one available on
[grst.github.io/immune_deconvolution_benchmark](https://grst.github.io/immune_deconvolution_benchmark)

## Getting started
Short version:
```
conda install snakemake
git clone git@github.com:grst/bioqc_geo.git
cd bioqc_geo
snakemake --use-conda
```

For details, see below.

### Prerequisites
This pipeline uses [Anaconda](https://conda.io/miniconda.html) and
[Snakemake](https://snakemake.readthedocs.io/en/stable/).

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

If you have problems retrieving the submodule, read this [question on
stackoverflow](https://stackoverflow.com/questions/3796927/how-to-git-clone-including-submodules).


### Run the pipeline
To perform all computations and to generate a HTML report with
[bookdown](https://bookdown.org/yihui/bookdown/) invoke
the corresponding `Snakemake` target:

```
snakemake --use-conda book
```

Make sure to use the `--use-conda` flag to tell Snakemake to download all dependencies from Anaconda.org.

The pipeline will generate a `results` folder.
The HTML report with all figures and results will be available in
`results/book`.

### Useful Snakemake targets.
Have a look at the `Snakefile`, it is self-explanatory.

A list of the most useful targets
```
snakemake --use-conda book       # generate a HTML-book in `results/book`
snakemake --use conda            # default target; = book
snakemake clean                  # cleans the HTML book
snakemake wipe                   # cleans everything, including all caches.
```

### preprocessed data
This pipeline makes use of the preprocesse BioQC results. 
Downloading the entire GEO and running BioQC on all samples 
takes a lot of computational resources. Therefore, 
we provide pre-calculated intermediate results, that 
are used by this pipeline. 

If you are interested in reproducing these files and
building the BioQC-GEO database from scratch, hava a look 
at [grst/BioQC_GEO_analysis](https://github.com/grst/BioQC_GEO_analysis). 
