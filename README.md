# gis2shiny

Generate interactive R Shiny maps and attribute tables from vector GIS data.

**Status:** initial unverified prototype (v0.1.0 development). Target: December 15, 2026.

## Install from a local checkout

```r
install.packages(c("sf", "shiny", "leaflet", "DT", "htmltools", "testthat", "devtools", "roxygen2"))
devtools::install(".")
```

## Example

```r
library(gis2shiny)
library(sf)
points <- st_as_sf(data.frame(group = c("A", "B"), x = c(-84.5, -84.4), y = c(39.1, 39.2)),
                   coords = c("x", "y"), crs = 4326)
app <- gis2shiny(points)
run_app(app)
export_app(app, "my_map_app")
```

Run `devtools::document()` before package checking to generate `.Rd` help files.
Run `devtools::test()` and `devtools::check()` to validate the package.

## Scope

Currently supports vector geometries (points, lines, polygons) from `sf` or files readable by `sf::st_read()`.
The exported app requires `gis2shiny` on the deployment server.
CRS must be defined. No raster support, custom styling, or multiple layers yet.
