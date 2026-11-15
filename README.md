# gis2shiny

Turn vector GIS data into interactive R Shiny dashboards with maps, filters,
summaries, and downloads.

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
points <- st_as_sf(data.frame(group = c("A", "B"), samples = c(8, 21),
                             x = c(-84.5, -84.4), y = c(39.1, 39.2)),
                   coords = c("x", "y"), crs = 4326)
app <- gis2shiny(points, filter_fields = "group", numeric_fields = "samples")
export_app(app, "my_map_app")
run_app(app)
```

To try a real dataset, run the North Carolina county example. It uses the
Shapefile bundled with `sf`.

```r
source(system.file("examples/nc-counties.R", package = "gis2shiny", mustWork = TRUE))
```

## Explore the dashboard

- Use the sidebar to select categories or enter inclusive numeric ranges.
  Blank or missing categories can be selected separately. Numeric filters
  start at the observed bounds and include missing and non-finite values by
  default when present.
- The first categorical filter with 2 to 20 choices determines map colors.
  The legend shows visible categories, and the layer menu on mixed-geometry
  maps toggles points, lines, and polygons independently.
- The **Summary** tab counts matching features by geometry type or the
  category used in the legend. The **Attributes** tab downloads all matching
  rows as CSV or as GeoJSON with geometry.

Set `filter_fields` and `numeric_fields` to choose sidebar controls. Omit
them for automatic selection or pass `character(0)` to disable either kind.
Use `popup_fields` to choose which attributes appear when you click a feature.

## Scope

Supply an `sf` object or a Shapefile, GeoJSON, or GeoPackage path. Keep Shapefile sidecars beside the `.shp` file. For a GeoPackage with several layers, the reader uses the first layer. The app supports point, line, polygon, and multipart geometries. Input needs a defined CRS and valid, nonempty geometries. The reader transforms the data to EPSG:4326 for the map.

## Export and run

Use `shiny::runApp("my_map_app")` to launch the exported project. Edit `app.R`
to change the title or selected fields, and keep `data.gpkg` beside it. Install
`gis2shiny` on the machine hosting the exported app. Exported project data uses
GeoPackage field types. Dashboard downloads write multi-value attributes as text
and represent non-finite numbers as null in GeoJSON.

## Development

Run `devtools::document()`, `devtools::test()`, and `devtools::check()` from the
package checkout. GitHub Actions checks Windows and Linux builds.
