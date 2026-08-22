SHELL := /bin/bash

PRESENTATION_HTML := presentation/index.html
ALL_TARGETS := $(PRESENTATION_HTML)
INCLUDED_MAKEFILES := $(addsuffix targets.mk,$(dir $(ALL_TARGETS)))

.DEFAULT_GOAL := all

include $(INCLUDED_MAKEFILES)

.PHONY: all
all: $(ALL_TARGETS)

.PHONY: watch-pres
watch-pres: $(PRESENTATION_HTML)
	inotifywait . -mr -e close_write --format '%w%f' | \
	while read -r closed_file; do \
		if [[ "$${closed_file}" =~ (Makefile|.*\.mk|.*\.qmd|.*\.scss|.*\.svg|.*\.jpg|.*\.png|.*\.webp|.*\.ico)$$ ]]; then \
			echo "Build triggered by '$$closed_file'."; \
			$(MAKE); \
		fi \
	done

.PHONY: open
open: open-presentation

.PHONY: check
check: $(PRESENTATION_HTML)
	uv run ruff check .
	uv run ty check
	uv run python -m py_compile presentation/print_pdf.py

.PHONY: audit
audit:
	uv audit --locked --preview-features audit-command

.PHONY: clean
clean: clean-presentation
