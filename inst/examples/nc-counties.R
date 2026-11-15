library(gis2shiny)

shape <- system.file("shape/nc.shp", package = "sf", mustWork = TRUE)
app <- gis2shiny(shape, title = "North Carolina Counties",
                  filter_fields = character(),
                  numeric_fields = c("BIR74", "AREA"),
                  popup_fields = c("NAME", "BIR74", "AREA"))
if (interactive()) run_app(app)
# export_app(app, "nc_counties_dashboard")
