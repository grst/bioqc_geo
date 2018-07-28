R=R
RMD_FILES= $(wildcard *.Rmd) 
PREVIEW_FILES = $(patsubst %,%.preview,$(RMD_FILES))
DATA_PATH= /pstore/data/bioinfo/users/sturmg/BioQC_GEO_analysis/gse_tissue_annot
CHUNKSUB_PATH= /pstore/data/bioinfo/users/sturmg/BioQC_GEO_analysis/chunksub
SHELL= /bin/bash
CHUNKSUB= /pstore/home/sturmg/.local/bin/chunksub
CWD= $(shell pwd)


#################################
# Render Rmarkdown documents
#################################

.PHONY: book
book: $(RMD_FILES)
	Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"

.PHONY: upload-book
upload-book: book
	cd gh-pages && cp -R ../_book/* ./ && git add --all * && git commit --allow-empty -m "update docs" && git push origin gh-pages

# render a chapter only by calling `make chapter1.Rmd.preview`
.PHONY: $(PREVIEW_FILES)
$(PREVIEW_FILES): %.Rmd.preview: %.Rmd
	Rscript -e "bookdown::preview_chapter('$<', 'bookdown::gitbook')"

.PHONY: clean
clean:
	rm -rfv *_book 
	rm -rfv _bookdown_files/*_files
	rm -fv _main*
	rm -rfv _notebooks/*

.PHONY: wipe
wipe: clean
	rm -rfv _bookdown_files


# rule to convert jupyter notebooks to markdown.  
_notebooks/%.md: notebooks/%.ipynb
	jupyter nbconvert --to markdown --output-dir _notebooks $< 
	# adjust realtive paths for images. 
	sed -i -r "s#!\[(.*)\]\((.*)\)#!\[\1\]\(_notebooks/\2\)#g" $@



##############################################
# make contamination heatmaps for all samples
##############################################

.PHONY: heatmaps
heatmaps: heatmaps_gtex_solid

heatmaps_gtex_solid:
	rm -rfv results/heatmaps_db/gtex_solid
	mkdir -p results/heatmaps_db/gtex_solid
	Rscript scripts/make_sample_heatmaps.R gtex_solid


#############################################
# download hgnc_symbols for BioQC filtering. 
#############################################
lib/res/hgnc_symbols.tsv:
	curl "ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/hgnc_complete_set.txt" | cut -f2 > $@


##################################
# GEO DOWNLOAD
# 
# create incremental list of files to download. 
# Then, run chunksub to download the files.
##################################
results/gse_lists/downloaded.txt: .FORCE
	find $(DATA_PATH)/geo | grep -oP "GSE(\d+)" | sort -u > $@ 

results/gse_lists/missing_download.txt: results/gse_lists/gse_tissue_annotation.txt results/gse_lists/downloaded.txt
	diff <(sort $(word 1,$^)) $(word 2,$^) | grep "^<" | grep -oP "GSE(\d+)" > $@ 

.PHONY: download_gse
download_gse: results/gse_lists/missing_download.txt
	# limit the number of concurrent jobs to 60
	$(eval CHUNKSIZE := $(shell wc -l results/gse_lists/missing_download.txt | awk '{print int($$1/60+1)}')) 
	rm -fr $(CHUNKSUB_PATH)/download_gse
	$(CHUNKSUB) -d $(CWD) -s $(CHUNKSIZE) -X y -N download_gse -j $(CHUNKSUB_PATH) "$(CWD)/scripts/geo_to_eset.R {} $(DATA_PATH)/geo" $< 




#################################
# GEO ANNOTATION
# 
# annotate expression sets with human orthologues for BioQC
#################################
results/gse_lists/annotated_esets.txt: .FORCE
	find $(DATA_PATH)/geo_annot | grep -oP "GSE(.*)\.Rdata" | sort -u > $@ 

results/gse_lists/downloaded_esets.txt: .FORCE
	find $(DATA_PATH)/geo | grep -oP "GSE(.*)\.Rdata" | sort -u > $@ 

results/gse_lists/missing_annotation.txt: results/gse_lists/downloaded_esets.txt results/gse_lists/annotated_esets.txt
	diff $^ | grep "^<" | grep -oP "GSE(.*)\.Rdata" | awk '{print "$(DATA_PATH)/geo/"$$0}' > $@

.PHONY: annotate_gse
annotate_gse: results/gse_lists/missing_annotation.txt
	$(eval CHUNKSIZE := $(shell wc -l $< | awk '{print int($$1/120+1)}'))
	rm -fr $(CHUNKSUB_PATH)/annotate_gse
	$(CHUNKSUB) -d $(CWD) -s $(CHUNKSIZE) -t /pstore/home/sturmg/.chunksub/roche_chunk.template -X y -N annotate_gse -j $(CHUNKSUB_PATH) "$(CWD)/scripts/annotate_eset.R $(DATA_PATH)/geo_annot {}" $< 



#################################
# GEO CONVERSION
# 
# convert the R expression sets to reuseable flatfiles (.gct, fdata.tsv, pdata.tsv)
#################################
results/gse_lists/converted_esets.txt: .FORCE
	find $(DATA_PATH)/geo_annot_flat | grep -oP "GSE(.*)\.gct" | sed  "s/_exprs\.gct/\.Rdata/" | sort -u > $@

results/gse_lists/missing_conversion.txt: results/gse_lists/annotated_esets.txt results/gse_lists/converted_esets.txt
	diff $^ | grep "^<" | grep -oP "GSE(.*)\.Rdata" | awk '{print "$(DATA_PATH)/geo_annot/"$$0}' > $@

.PHONY: convert_geo
convert_geo: results/gse_lists/missing_conversion.txt
	$(CHUNKSUB) -d $(CWD) -s 20 -X y -N convert_geo -j $(CHUNKSUB_PATH) "$(CWD)/scripts/eset_to_gct.R {} $(DATA_PATH)/geo_annot_flat" $<

#################################
# BioQC
#
# apply BioQC to the annotated expression sets
#
# Import the bioqc_melt_all_uniq.tsv manually using Sqldeveloper. 
#################################

.PHONY: clean_bioqc
clean_bioqc: 
	rm -rfv $(DATA_PATH)/bioqc_melt_all*.tsv
	rm -rfv $(DATA_PATH)/bioqc
	mkdir -p $(DATA_PATH)/bioqc
	rm -rfv $(DATA_PATH)/bioqc_success.csv

results/gse_lists/bioqced_esets.txt: .FORCE
	find $(DATA_PATH)/bioqc | grep -oP "GSE(.*)_bioqc_res_melt\.tab" | sort -u > $@

results/gse_lists/missing_bioqc.txt: results/gse_lists/annotated_esets.txt results/gse_lists/bioqced_esets.txt
	diff $(word 1,$^) <(sed s/_bioqc_res_melt\.tab/\.Rdata/ $(word 2,$^)) | grep "^<" | grep -oP "GSE(.*)\.Rdata" | awk '{print "$(DATA_PATH)/geo_annot/"$$0}' > $@

.PHONY: run_bioqc
run_bioqc: results/gse_lists/missing_bioqc.txt results/gmt_all.gmt
	rm -fr $(CHUNKSUB_PATH)/bioqc
	$(CHUNKSUB) -d $(CWD) -s 10 -t /pstore/home/sturmg/.chunksub/roche_chunk.template -X y -N bioqc -j $(CHUNKSUB_PATH) "$(CWD)/scripts/run_bioqc.R $(DATA_PATH)/bioqc $(word 2,$^) {} 2" $< 

.PHONY: bioqc_res
bioqc_res: $(DATA_PATH)/bioqc_melt_all.uniq.tsv $(DATA_PATH)/bioqc_success.csv

$(DATA_PATH)/bioqc_melt_all.tsv: results/gse_lists/bioqced_esets.txt 
	awk '{print "$(DATA_PATH)/bioqc/"$$0}' < $< | xargs cat > $@

$(DATA_PATH)/bioqc_melt_all.uniq.tsv:  $(DATA_PATH)/bioqc_melt_all.tsv
	# unique on first two columns. For one study the results exactely identical
	# due to floating point inprecision, but identical up to 5 decimal digits (i checked)
	bash_wrapper.sh 24 "sort --parallel 24 -u -k1,2 $< > $@ "

$(DATA_PATH)/bioqc_success.csv:
	# list of GSM on which the bioqc-run was successful. Serves as 'background' for 
	# the analysis. 
	rm -f $@.tmp
	for f in $$(find $(DATA_PATH)/bioqc -iname "*bioqc_res.tab"); do head -n 1 $$f >> $@.tmp;	done
	tr " " "\n" < $@.tmp | tr -d '"' | sort -u > $@
	rm -f $@.tmp

##################################
# Calculate Mean and quantiles for each ExpressionSet. 
# This is useful for finding out whether the samples have
# been normalized. 
#################################

.PHONY: test_for_normalization 
test_for_normalization: results/gse_lists/annotated_esets.txt 
	rm -fr $(CHUNKSUB_PATH)/test_for_normalization
	rm -fr $(DATA_PATH)/test_for_normalization
	mkdir -p $(DATA_PATH)/test_for_normalization
	awk '{print "$(DATA_PATH)/geo_annot/"$$0}' < $< | $(CHUNKSUB) -d $(CWD) -s 50 -t /pstore/home/sturmg/.chunksub/roche_chunk.template -X y -N test_for_normalization -j $(CHUNKSUB_PATH) "$(CWD)/scripts/test_for_normalization.R $(DATA_PATH)/test_for_normalization/ {}" 

$(DATA_PATH)/study_stats.txt: 
	find $(DATA_PATH)/test_for_normalization/ -iname "*.txt" | head -n 1 | xargs awk 'FNR==1{print "filename\t" $$0}' > $@ 
	find $(DATA_PATH)/test_for_normalization/ -iname "*.txt" | xargs awk 'FNR==2{print FILENAME "\t" $$0}' >> $@


# empty target can be used to force regeneration of files
.FORCE:
