# $Id: Makefile 51 2015-06-01 13:32:57Z lohmann $

# PDF images are stored here
FIG_DIR   := fig

# TikZ source files (.tikz) are stored here
TIKZ_DIR	:= fig/tikz

# The output directory for temporary output to be used by pdflatex and X
BUILD_DIR ?= build


SHELL := bash

# TikZ images are stored in fig/tikz and match *.tikz. they can
# be includegraphics'ed as PDF from fig/
TIKZ_SRC	:= $(shell find $(TIKZ_DIR) -name "*.tikz")
TIKZ_PDF	:= $(addprefix $(FIG_DIR)/,$(notdir $(TIKZ_SRC:.tikz=.pdf)))
TIKZ_DEPS	:= tikz.styles $(TIKZ_DIR)/tikz.frame

# TikZ images are compiled to PDF by pdflatex by inputing them in fig/tikz/tikz.frame
TIKZ_CC		= pdflatex -halt-on-error -output-directory=$(BUILD_DIR) -jobname=$(<F:.tikz=) "\def\TheTikzFile{$<}\input{$(TIKZ_DIR)/tikz.frame}"

TEX_CC	= latexmk -pdf -use-make -output-directory=$(BUILD_DIR) -latex=pdflatex -latexoption='-synctex=1'

REDIRECT	?=>/dev/null 2>/dev/null
ERRFILT		?= $(if $(shell which rubber-info), rubber-info, grep -1 "^[\!l][\. ]")
ERRFILT		:= grep -1 "^[\!l][\. ]"


#####################################################################
#
# Build rules for graphics (in FIG_DIR)
#
#####################################################################

# compile a fig/tik/%.tikz file to PDF and copy the result to fig/%.pdf
$(FIG_DIR)/%.pdf : $(TIKZ_DIR)/%.tikz $(TIKZ_DEPS)
	@mkdir -p $(BUILD_DIR); $(TIKZ_CC)  $(REDIRECT) \
	&& $(TIKZ_CC) $(REDIRECT) \
		&& cp  $(BUILD_DIR)/$(<F:.tikz=.pdf) $@ \
    && echo "[ok]    $@" \
	|| ( echo "[ERROR] $@:" ; cd $(BUILD_DIR); $(ERRFILT) $(<F:.tikz=.log) )

# convert an svg document from FIG_DIR/svg to a PDF
$(FIG_DIR)/%.pdf : $(FIG_DIR)/svg/%.svg
	@echo -n "        [svg-->pdf (inkscape)..." && \
	inkscape -A $@ $< $(REDIRECT) \
		&& (echo "]" ; echo "[ok]    $@") \
		|| (echo "]" ; echo "[ERROR] $@:")

# sanitize (make printer-friendly) a PDF image in fig/
# by conerting it to PS and back. All fonts become curves,
# text is no longer selectable.
#
# Use in case of printing problems
#
$(FIG_DIR)/%-sanitized.pdf : $(FIG_DIR)/%.pdf
	@echo -n "        [sanitizing pdf..." && \
	pdf2ps $< $(FIG_DIR)/$*.ps $(REDIRECT) && \
	ps2pdf $(FIG_DIR)/$*.ps $@ $(REDIRECT) && \
	rm -f $(FIG_DIR)/$*.ps \
		&& (echo "]" ; echo "[ok]    $@") \
		|| (echo "]" ; echo "[ERROR] $@:")


#####################################################################
#
# All and clean stuff
#
#####################################################################

all: slides.pdf

%.pdf: build/%.pdf
	cp build/$(@F) .

build/slides.pdf: slides.tex ${TIKZ_PDF}
	$(TEX_CC) slides.tex

.PRECIOUS: build/%.pdf


all_tikz: $(TIKZ_PDF)


clean_tikz:
	rm -f $(TIKZ_PDF)

clean:
	rm -rf build

distclean: clean
	rm -rf pdf

.PHONY: build/%.pdf clean clean_tikz distclean %.dep default all pubpdf
