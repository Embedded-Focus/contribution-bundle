# Contribution Bundle

This repository contains the source files for a Quarto/reveal.js presentation
bundle. The deck is written in Markdown-flavoured Quarto (`.qmd`) and can be
rendered to HTML for presenting in a browser or exported to PDF with Playwright.

The current presentation content is intentionally generic and demonstrates the
capabilities of the presentation system: sections, speaker notes, columns,
figures, tables, code blocks, callouts, footer content, and backup slides.

## Requirements

The project is set up for a Nix/devenv-based workflow and uses `uv` for Python
dependency management.

Main tools:

- Python 3.14
- `uv`
- Quarto CLI
- Playwright
- GNU Make
- `inotifywait` for the optional `watch-pres` target

The Python dependencies are declared in [pyproject.toml](pyproject.toml).

## Development Environment

If you use `direnv` and `devenv`, enter the repository and allow the environment:

```bash
direnv allow
```

Alternatively, enter the development shell directly:

```bash
devenv shell
```

The devenv configuration enables Python, `uv`, and the runtime libraries needed
by Playwright/Chromium.

## Build the Presentation

Render the reveal.js presentation:

```bash
make
```

This generates:

```text
presentation/index.html
```

During the build, the placeholder `<git-hash>` in the rendered footer is
replaced with the current short Git commit hash.

## Preview Locally

Open the generated presentation directly in your default browser:

```bash
make open
```

Serve the generated presentation from the `presentation/` directory:

```bash
make http
```

Or use the root convenience target with automatic rebuilds:

```bash
make watch-pres
```

This target requires `inotifywait`.

Then open the printed local URL in a browser.

## Export to PDF

Generate a PDF export:

```bash
make presentation/contribution_bundle.pdf
```

The export flow renders the HTML deck, starts a temporary local HTTP server, and
uses Playwright/Chromium to print the reveal.js presentation to PDF.

## Clean Generated Files

Remove generated presentation artifacts:

```bash
make clean
```

## Checks and Security Audit

Run the same local checks used by CI:

```bash
make check
```

Audit the locked Python dependencies with `uv audit`:

```bash
make audit
```

## Editing the Deck

The main deck source is:

```text
presentation/contribution_bundle.qmd
```

Theme customization lives in:

```text
presentation/embedded_focus_quarto_theme.scss
```

Presentation graphics are stored in:

```text
presentation/img/
```

Root-level presentation assets, such as `embedded_focus_logo.svg` and
`favicon.ico`, live directly in `presentation/`.

When adding or replacing images, keep paths relative to `presentation/`, because
Quarto renders the deck from that directory.

## Useful Commands

```bash
# Build HTML presentation
make

# Rebuild automatically while editing
make watch-pres

# Open generated HTML in a browser
make open

# Serve from presentation/
make http

# Export PDF
make presentation/contribution_bundle.pdf

# Run local checks
make check

# Audit locked dependencies
make audit

# Clean generated files
make clean
```
