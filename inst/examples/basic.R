library(gis2shiny)
library(sf)
places <- data.frame(
  city = c("Cincinnati", "Columbus", "Cleveland"),
  category = c("A", "B", "A"),
  sample_count = c(8, 14, 21),
  longitude = c(-84.5120, -82.9988, -81.6944),
  latitude = c(39.1031, 39.9612, 41.4993)
)
spatial <- st_as_sf(places, coords = c("longitude", "latitude"), crs = 4326)
app <- gis2shiny(spatial, title = "Ohio Cities",
                  filter_fields = "category", numeric_fields = "sample_count")
if (interactive()) run_app(app)
# export_app(app, "ohio_dashboard")
