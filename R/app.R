# Internal Shiny application builder
build_shiny_app <- function(spec) {
  if (!inherits(spec, "gis2shiny_app")) stop("Expected a gis2shiny_app.", call. = FALSE)
  data <- spec$data
  fields <- spec$filter_fields
  ui <- shiny::fluidPage(
    shiny::titlePanel(spec$title),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        lapply(seq_along(fields), function(i) {
          field <- fields[[i]]
          values <- sort(unique(as.character(stats::na.omit(data[[field]]))))
          shiny::selectInput(paste0("filter_", i), field,
                             choices = values, selected = values, multiple = TRUE)
        })
      ),
      shiny::mainPanel(
        leaflet::leafletOutput("map", height = 550),
        DT::DTOutput("attributes")
      )
    )
  )
  server <- function(input, output, session) {
    filtered <- shiny::reactive({
      d <- data
      for (i in seq_along(fields)) {
        selected <- input[[paste0("filter_", i)]]
        if (is.null(selected)) selected <- character()
        d <- d[!is.na(d[[fields[[i]]]]) & as.character(d[[fields[[i]]]]) %in% selected, ]
      }
      d
    })
    output$map <- leaflet::renderLeaflet({
      d <- filtered()
      m <- leaflet::leaflet(options = leaflet::leafletOptions(preferCanvas = TRUE)) |>
        leaflet::addTiles()
      if (nrow(d) == 0L) return(m)
      labels <- popup_html(d, spec$popup_fields)
      typ <- as.character(sf::st_geometry_type(d))
      points <- typ %in% c("POINT", "MULTIPOINT")
      lines <- typ %in% c("LINESTRING", "MULTILINESTRING")
      polygons <- typ %in% c("POLYGON", "MULTIPOLYGON")
      if (any(points)) m <- leaflet::addCircleMarkers(m, data = d[points, ], popup = labels[points], radius = 5)
      if (any(lines)) m <- leaflet::addPolylines(m, data = d[lines, ], popup = labels[lines])
      if (any(polygons)) m <- leaflet::addPolygons(m, data = d[polygons, ], popup = labels[polygons], fillOpacity = 0.5)
      bbox <- sf::st_bbox(d)
      if (all(is.finite(bbox))) {
        m <- leaflet::fitBounds(m, lng1 = unname(bbox["xmin"]), lat1 = unname(bbox["ymin"]),
                                lng2 = unname(bbox["xmax"]), lat2 = unname(bbox["ymax"]))
      }
      m
    })
    output$attributes <- DT::renderDT({
      DT::datatable(sf::st_drop_geometry(filtered()), options = list(pageLength = 10), rownames = FALSE)
    })
  }
  shiny::shinyApp(ui, server)
}

popup_html <- function(data, fields) {
  if (length(fields) == 0L) return(rep("Feature", nrow(data)))
  attrs <- sf::st_drop_geometry(data)
  vapply(seq_len(nrow(attrs)), function(i) {
    paste(vapply(fields, function(field) {
      val <- as.character(attrs[[field]][i])
      if (is.na(val)) val <- "NA"
      paste0("<strong>", htmltools::htmlEscape(field), "</strong>: ",
             htmltools::htmlEscape(val))
    }, character(1)), collapse = "<br/>")
  }, character(1))
}

#' Run a generated Shiny application
#' @param app A `gis2shiny_app` specification.
#' @param ... Additional arguments passed to `shiny::runApp()`.
#' @export
run_app <- function(app, ...) {
  shiny::runApp(build_shiny_app(app), ...)
}
