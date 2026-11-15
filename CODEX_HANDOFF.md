# gis2shiny: complete project handoff to Codex Desktop

**Repository:** https://github.com/david-amakye/gis2shiny  
**Deadline:** 2026-12-15 (v0.1.0 GitHub release)  
**Development started:** 2026-11-15  
**Status:** unverified starter prototype; R checks still required.

## Research and positioning
Existing packages supporting overlapping functionality include mapview (interactive maps from spatial data), mapedit (spatial editing/selecting), mapgl (interactive maps with Shiny integration), geolibre (GIS environment in Shiny/Quarto), and smartmap (quick spatial maps). `gis2shiny` should NOT claim novelty in GIS-to-interactive maps. Its focused value proposition is automatic generation of **complete editable Shiny applications** from ordinary GIS datasets and `sf` objects with low code.

## User-approved scope
Start with GIS vector data and `sf`, not existing QGIS/ArcGIS map project files. Input formats: .shp (with sidecars), .geojson, .gpkg, and `sf`. Handle point, line, polygon and multipart geometry. MVP: validation + CRS, auto-map, popups/legends, filters, table, charts/downloads, run locally, editable export; deliver as maintainable package.

## Suggested code architecture
`R/read-gis.R` input/validation; `R/gis2shiny.R` object specification and print; `R/app.R` Shiny builder, map and UI, escaping; `R/export-app.R` export. Break large parts into small modules as needed. Package metadata in DESCRIPTION and roxygen2-generated NAMESPACE/man; tests in tests/testthat, example in inst/examples.

## Existing status
The source contains `read_gis`, `gis2shiny`, `run_app`, `export_app` and `print.gis2shiny_app`, rendering points/lines/polygons on Leaflet, categorical filter selects, an attributes table and escaped HTML popups. Existing limitations: no numeric filters, legends, charts, download controls, fully self-contained export or tests verified by execution. The current export includes app.R + data.gpkg and requires the package at destination. Do not claim beyond present capabilities.

## Roadmap
Week 1 (Nov 15-21): bootstrap, input/CRS, tests.
Week 2 (Nov 22-28): reactive map & filters/legends/popups.
Week 3 (Nov 29-Dec 5): charts, tables, exports, representative datasets.
Week 4 (Dec 6-15): documentation, tests, CI, GitHub release.

## First run procedure
1. Open local clone of this repository with Codex Desktop.
2. Make sure source ZIP is extracted at the repository root (DESCRIPTION should be at repo root, NOT nested in `gis2shiny/gis2shiny/`).
3. Read `AGENTS.md`; audit package metadata, source and tests.
4. Run R package documentation, tests, and check. Do not claim success before running.
5. Fix bugs, include tests, and create a focused PR. Report blockers.

## Relevant R commands
```r
install.packages(c('devtools', 'roxygen2'))
devtools::document()
devtools::test()
devtools::check()
devtools::install()

library(gis2shiny)
example <- sf::st_as_sf(data.frame(lon = c(-84.5, -84.48), lat = c(39.1, 39.12), group = c('A','B')), coords = c('lon', 'lat'), crs = 4326)
app <- gis2shiny(example)
run_app(app)
export_app(app, 'my_gis_dashboard')
```

Note the earlier prototype may need fixes for this sample to run. This is a test target, not a verified demonstration.
