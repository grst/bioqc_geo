
```r
library(stringr)
library(readr)
library(MASS)
source("config.R")
library(cowplot)
```

```
## Loading required package: ggplot2
```

```
## 
## Attaching package: 'cowplot'
```

```
## The following object is masked from 'package:ggplot2':
## 
##     ggsave
```

```r
library(boot)
library(dplyr)
```

```
## 
## Attaching package: 'dplyr'
```

```
## The following object is masked from 'package:MASS':
## 
##     select
```

```
## The following objects are masked from 'package:stats':
## 
##     filter, lag
```

```
## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union
```

```r
select = dplyr::select
```


# Figures for publication



Same as in the section before, but all bioqc signatures aggregated by tissue groups.
Additional, we define samples as being "severely heterogeneous", if the reference signature,
i.e. the signature that should be present according to the annotation, is not enriched at 
an unadjusted p-value < 0.05.







We use bootstrapping (R package `boot`) to derive confidence intervals. 



```
## Saving 8 x 4.5 in image
## Saving 8 x 4.5 in image
```


```r
plot_grid(p1, p2, align = "v", nrow=2, rel_heights = c(.5, .6), labels = "AUTO", axis="lr")
```

<img src="95_figures_files/figure-html/unnamed-chunk-6-1.png" width="768" />

```r
ggsave("../results/figures/heterogeneity_main.pdf")
```

```
## Saving 8 x 9 in image
```

```r
ggsave("../results/figures/heterogeneity_main.png")
```

```
## Saving 8 x 9 in image
```
