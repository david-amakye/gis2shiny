# gis2shiny

Generate interactive R Shiny maps and attribute tables from vector GIS data.

**Status:** v0.1.0 in development. Target release is December 15, 2026.

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
export_app(app, "my_map_app")
run_app(app)
```

Run `devtools::document()` before package checking to generate `.Rd` help files.
Run `devtools::test()` and `devtools::check()` to validate the package.

## Scope

Supply an `sf` object or a Shapefile, GeoJSON, or GeoPackage path. Keep Shapefile sidecars beside the `.shp` file. For a GeoPackage with several layers, the reader uses the first layer. The app supports point, line, polygon, and multipart geometries. Input needs a defined CRS and valid, nonempty geometries. The reader transforms the data to EPSG:4326 for the map.

Use `shiny::runApp("my_map_app")` to launch the exported project. Edit `app.R` to change the title or selected fields, and keep `data.gpkg` beside it. Install `gis2shiny` on the machine hosting the exported app.

Filters update the map and attribute table together. Blank and missing values can be selected separately. The first filter field with 2 to 20 categories determines map colors, and the legend lists the categories currently visible. To choose which field supplies the colors, list it first in `filter_fields`.
