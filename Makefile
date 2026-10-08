############################
# Usage
# make         # converts all src/*.tex files to publish/*.pdf files using lualatex
# make clean   # cleans up publish/*.pdf artifacts
############################

all:

############################
# Common
############################

LATEXMK = latexmk

PUBLISH_DIR = publish
SRC_DIR = src
IMAGES_DIR = images
COMMON_DIR = common
BUILD_DIR = build

############################
# Targets
############################

SRC  = $(wildcard $(SRC_DIR)/*.tex)
PDF  = $(SRC:.tex=.pdf)

PDF_PUBLISH = $(PDF:$(SRC_DIR)/%=$(PUBLISH_DIR)/%)
PDF_NAMES = $(PDF:$(SRC_DIR)/%.pdf=%)

PNG_ROOT = $(wildcard $(IMAGES_DIR)/*.png)
PNG_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.png))
PNG = $(PNG_ROOT) $(PNG_TARGET)

SVG_ROOT = $(wildcard $(IMAGES_DIR)/*.svg)
SVG_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.svg))
SVG_PDF_ROOT = $(SVG_ROOT:.svg=.pdf)
SVG_PDF_TARGET = $(SVG_TARGET:.svg=.pdf)
SVG_PDF = $(SVG_PDF_ROOT) $(SVG_PDF_TARGET)

DOT_ROOT = $(wildcard $(IMAGES_DIR)/*.gv)
DOT_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.gv))
DOT_PDF_ROOT = $(DOT_ROOT:.gv=.pdf)
DOT_PDF_TARGET = $(DOT_TARGET:.gv=.pdf)
DOT_PDF = $(DOT_PDF_ROOT) $(DOT_PDF_TARGET)

DOC     = $(wildcard $(SRC_DIR)/*.doc)
DOC_PDF = $(DOC:.doc=.pdf)

############################
# Goals
############################

.PHONY: all clean pdf
.DEFAULT_GOAL := all

all: pdf

publish: $(PDF_PUBLISH)
pdf:  $(PDF)

clean: 
	@echo "Cleaning up..."
	rm -rvf $(PDF) $(SVG_PDF) $(DOT_PDF) $(DOC_PDF) $(BUILD_DIR)

watch:
	@find $(SRC_DIR) $(IMAGES_DIR) $(COMMON_DIR) -type f | entr -c make

############################
# Publish patterns
############################

$(PDF_PUBLISH): $(PUBLISH_DIR)/%.pdf: $(SRC_DIR)/%.pdf
	@mkdir -p $(@D)
	cp $< $@

############################
# LaTeX patterns
############################

$(PDF): %.pdf: %.tex
	$(LATEXMK) -halt-on-error -lualatex $< -output-directory=$(BUILD_DIR) >/dev/null 2>&1 \
		|| (tail -n25 $(BUILD_DIR)/$(notdir $(basename $@)).log; exit 1)
	cp $(BUILD_DIR)/$(notdir $@) $@
	
############################
# Image patterns
############################

$(SVG_PDF): %.pdf: %.svg
	@# SELF_CALL is workaround for running inkscape in parallel
	@# See https://gitlab.com/inkscape/inkscape/-/issues/4716
	SELF_CALL=no inkscape -D $< -o $@


$(DOT_PDF): %.pdf: %.gv
	dot -Tpdf $< -o $@

$(DOC_PDF): %.pdf: %.doc
	soffice --headless --convert-to pdf --outdir $(dir $@) $<

############################
# Custom patterns
############################


TARGET_IMAGE_DEPS = $(filter $(IMAGES_DIR)/$*/%,$(DOT_PDF_TARGET) $(SVG_PDF_TARGET) $(PNG_TARGET))
ROOT_IMAGE_DEPS = $(filter $(IMAGES_DIR)/%,$(DOT_PDF_ROOT) $(SVG_PDF_ROOT) $(PNG_ROOT))

.SECONDEXPANSION:
$(PDF): $(SRC_DIR)/%.pdf: $(ROOT_IMAGE_DEPS) $(COMMON_PNG_IMAGE_DEPS) $$(TARGET_IMAGE_DEPS) $(DOC_PDF)

$(PDF): $(COMMON_DIR)/preamble.tex $(COMMON_DIR)/citations.bib $(COMMON_DIR)/gost/gost-r-7-0-5-2008-numeric.csl


