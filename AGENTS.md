# Codex development instructions — gis2shiny

## Project and purpose
Repository: https://github.com/david-amakye/gis2shiny
Working package name: `gis2shiny`.
Goal: turn vector GIS datasets and `sf` objects into interactive, customizable R Shiny applications with minimal user code. Differentiate from map widgets by producing a full app with map, controls, table, and editable export.
**Target GitHub v0.1.0 release: December 15, 2026** (project target, not a promise).

## Decisions from November 15, 2026 conversation
- V0.1.0 supports in-memory `sf`, ESRI Shapefile, GeoJSON, and GeoPackage via `sf`. Initial geometry support: point, line, polygon, including common MULTI variants.
- Existing QGIS and ArcGIS project conversion, raster import, advanced GIS symbology and spatial editing are **out of scope** for v0.1.0.
- Main public interface proposed: `gis2shiny(x, ...)`, `read_gis(x)`, `run_app(app)`, `export_app(app, path)`, plus `print.gis2shiny_app`.
- Intended workflow:
  ```r
  library(gis2shiny)
  app <- gis2shiny('data/districts.gpkg')
  run_app(app)
  export_app(app, 'my_gis_dashboard')
  ```
- Expected capabilities over the month: validation/CRS handling; automatic Leaflet map; attribute filters, legend/popups and layer controls; table; simple linked summary charts; data downloads; editable Shiny export.
- Engineering stack: R, sf, shiny, leaflet, DT, htmltools; evaluate bslib and ggplot2 for planned UI/chart features. Prefer modular code and lean dependencies.

## Architecture
1. Input: `read_gis` reads spatial files or accepts `sf`, checks nonempty geometry and CRS, converts to EPSG:4326 for Leaflet.
2. Specification: `gis2shiny` returns an inspectable `gis2shiny_app` specification with data, title, popup/filter fields, and future options.
3. Renderer: independent Shiny UI/server builder handling reactive filtering, geometry-specific mapping, popups, summary components, and attributes.
4. Exporter: export app.R and its data/assets as editable project. Currently exported project depends on `gis2shiny` installed on its host. Do not falsely claim fully standalone.

## Process & coding standards
- Treat the imported prototype as **unverified starter code**. It was authored without running R. Audit it before extending it.
- Preserve user work; inspect repository state first and work on a feature branch / pull request if appropriate. Don't force push, remove unrelated content, or merge without explicit instruction.
- Use standard R package structure (DESCRIPTION, NAMESPACE, R/, man/, tests/testthat/, inst/, optional vignettes/). Generate documentation using roxygen2 rather than hand-editing generated NAMESPACE/man files.
- Run `devtools::document()`, `devtools::test()`, `devtools::check()` (or `R CMD check`) where R available, recording actual outputs. Never report passing tests that have not been executed.
- Add tests for sf input, file paths/format failure, point/line/polygon and MULTI geometries, missing CRS, invalid geometry, empty features, bad filters, popup HTML escaping, empty filtered views and exported-app smoke tests.
- Be mindful of cross-platform Windows/Linux path behavior; keep input data portable, no hardcoded user paths.
- Do not commit credentials, confidential datasets, or API keys. Avoid machine-wide changes without user approval.
- Maintain README, examples, CI and a changelog as changes land. Use actionable commits and report blockers.
- Fix placeholders in DESCRIPTION (e.g. `maintainer@example.org`) with user-approved real maintainer info or appropriate non-placeholder details before release; do not invent email addresses.

## Weekly plan
- **Nov 15–21:** import package source, fix packaging errors, robust reader/geometry/CRS validation, tests.
- **Nov 22–28:** Shiny renderer for geometry types, popups, categorical filters and data table.
- **Nov 29–Dec 5:** numeric filtering, legends, charting/downloads, app export and real datasets.
- **Dec 6–15:** docs, example apps, broad test coverage, CI, R CMD check, GitHub v0.1.0 release.

## Acceptance criteria
On a working R environment, users can install the package, provide supported spatial data, run an interactive Shiny dashboard, and export an editable Shiny project; documentation and tests substantiate these claims. R CMD check must pass before release or exceptions be disclosed.

## Starter project notes
The initial files have been included in this repo handoff as source, and an original archive is preserved separately by the user. `README.md`, `DESCRIPTION`, `R/*.R`, `tests/testthat`, `inst/examples/basic.R` exist but have not been verified through runtime tests. `bslib`, `ggplot2`, full choropleth and charts are future additions, not existing implemented functions. The DESCRIPTION uses a placeholder maintainer email and warrants correction.

## Immediate Codex task
1. Inspect the imported source, README, AGENTS.md and working tree.
2. Run baseline `devtools::document()`, `devtools::test()`, and `devtools::check()`; log any missing dependency/platform limitations.
3. Fix critical defects, add regression tests and README quick-start without unnecessary feature creep.
4. Commit to a `codex/bootstrap-v0.1.0` branch and open a PR against main when possible; clearly report exact commands/results.
