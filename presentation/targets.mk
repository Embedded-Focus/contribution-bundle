PRESENTATION_MKFILE := $(lastword $(MAKEFILE_LIST))
PRESENTATION_DIR := $(patsubst %/,%,$(dir $(PRESENTATION_MKFILE)))
PRESENTATION_ABS_DIR := $(abspath $(PRESENTATION_DIR))

PRESENTATION_BASENAME := contribution_bundle
PRESENTATION_MAIN := $(PRESENTATION_DIR)/$(PRESENTATION_BASENAME).qmd
PRESENTATION_THEME := $(PRESENTATION_DIR)/embedded_focus_quarto_theme.scss
PRESENTATION_LOGO := $(PRESENTATION_DIR)/embedded_focus_logo.svg
PRESENTATION_FAVICON := $(PRESENTATION_DIR)/favicon.ico
PRESENTATION_PRINT_PDF := $(PRESENTATION_DIR)/print_pdf.py
PRESENTATION_HTML := $(PRESENTATION_DIR)/index.html
PRESENTATION_HTML_FILES := $(PRESENTATION_DIR)/$(PRESENTATION_BASENAME)_files
PRESENTATION_PDF := $(PRESENTATION_DIR)/$(PRESENTATION_BASENAME).pdf
PRESENTATION_DIST := $(PRESENTATION_DIR)/$(PRESENTATION_BASENAME).zip
PRESENTATION_TOOL_DEPS := pyproject.toml uv.lock

PRESENTATION_IMAGE_DEPS := \
	$(PRESENTATION_DIR)/img/architecture.svg \
	$(PRESENTATION_DIR)/img/qr_https_embedded_focus_com.svg \
	$(PRESENTATION_DIR)/img/qr_https_honeytreelabs_com.svg \
	$(PRESENTATION_DIR)/img/rpoisel.jpg

PRESENTATION_HTML_DEPS := \
	$(PRESENTATION_MAIN) \
	$(PRESENTATION_THEME) \
	$(PRESENTATION_LOGO) \
	$(PRESENTATION_IMAGE_DEPS) \
	$(PRESENTATION_TOOL_DEPS)

PRESENTATION_DIST_DEPS := \
	$(PRESENTATION_HTML) \
	$(PRESENTATION_FAVICON) \
	$(PRESENTATION_LOGO) \
	$(PRESENTATION_IMAGE_DEPS)

$(PRESENTATION_DIR)/img:
	mkdir -p $@

$(PRESENTATION_HTML): $(PRESENTATION_HTML_DEPS) | $(PRESENTATION_DIR)/img
	cd $(@D) && uv run quarto render $(notdir $(PRESENTATION_MAIN)) --output $(@F) --to revealjs
	cd $(@D) && \
		sed -E -i.bak "s/<git-hash>/$$(git rev-parse --short HEAD)/" $(@F) && \
		rm -f $(@F).bak

$(PRESENTATION_PDF): $(PRESENTATION_HTML) $(PRESENTATION_PRINT_PDF)
	tmp_stem=".$(PRESENTATION_BASENAME).pdf.$$$$"; \
	tmp_qmd="$(PRESENTATION_ABS_DIR)/$$tmp_stem.qmd"; \
	tmp_html="$$tmp_stem.html"; \
	tmp_files="$$tmp_stem""_files"; \
	trap 'rm -f "$$tmp_qmd" "$$tmp_qmd.bak" "$(PRESENTATION_ABS_DIR)/$$tmp_html"; rm -rf "$(PRESENTATION_ABS_DIR)/$$tmp_files"' EXIT; \
	cp "$(PRESENTATION_MAIN)" "$$tmp_qmd"; \
	sed -E -i.bak '/^[[:space:]]*<!--/! s/^[[:space:]]*(\{\{<[[:space:]]*video[^}]*>}})[[:space:]]*$$/<!-- \1 -->/' "$$tmp_qmd"; \
	cd "$(PRESENTATION_DIR)" && \
		uv run quarto render "$$(basename "$$tmp_qmd")" --output "$$tmp_html" --to revealjs && \
		sed -E -i.bak "s/<git-hash>/$$(git rev-parse --short HEAD)/" "$$tmp_html" && \
		rm -f "$$tmp_html.bak" && \
		uv run python "$(notdir $(PRESENTATION_PRINT_PDF))" --input "$$tmp_html" --output "$(notdir $(PRESENTATION_PDF))"

$(PRESENTATION_DIST): $(PRESENTATION_DIST_DEPS)
	cd $(@D) && \
		rm -f $(@F) && \
		zip -v9ur $(@F) \
			$(notdir $(PRESENTATION_HTML)) \
			$(notdir $(PRESENTATION_HTML_FILES)) \
			$(notdir $(PRESENTATION_FAVICON)) \
			$(notdir $(PRESENTATION_LOGO)) \
			img

.PHONY: http
http: $(PRESENTATION_HTML)
	cd $(PRESENTATION_DIR) && uv run python -m http.server

.PHONY: open-presentation
open-presentation: $(PRESENTATION_HTML)
	html_path="$$(realpath "$(PRESENTATION_HTML)")"; \
	if [[ -n "$${BROWSER:-}" ]]; then \
		$$BROWSER "$$html_path"; \
	elif command -v xdg-open >/dev/null 2>&1; then \
		xdg-open "$$html_path"; \
	elif command -v open >/dev/null 2>&1; then \
		open "$$html_path"; \
	else \
		echo "No browser opener found. Set BROWSER or open '$$html_path' manually."; \
		exit 1; \
	fi

.PHONY: clean-presentation
clean-presentation:
	-cd $(PRESENTATION_DIR) && rm -rf \
		$(notdir $(PRESENTATION_HTML)) \
		$(notdir $(PRESENTATION_HTML_FILES)) \
		$(notdir $(PRESENTATION_PDF)) \
		$(notdir $(PRESENTATION_DIST)) \
		.$(PRESENTATION_BASENAME).pdf.*
