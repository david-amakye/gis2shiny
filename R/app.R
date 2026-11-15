# Internal Shiny application builder
build_shiny_app <- function(spec) {
  if (!inherits(spec, "gis2shiny_app")) stop("Expected a gis2shiny_app.", call. = FALSE)
  data <- spec$data
  fields <- spec$filter_fields
  filters <- lapply(fields, function(field) {
    column <- data[[field]]
    values <- as.character(column)
    values[is.na(column)] <- NA_character_
    choices <- sort(unique(values), na.last = TRUE)
    labels <- choices
    labels[which(choices == "")] <- "(blank)"
    labels[is.na(choices)] <- "(missing)"
    label_order <- order(is.na(choices) | choices == "")
    labels[label_order] <- make.unique(labels[label_order], sep = " ")
    list(choices = stats::setNames(as.character(seq_along(choices)), labels),
         value_ids = match(values, choices))
  })
  counts <- vapply(filters, function(filter) length(filter$choices), integer(1))
  legend_index <- match(TRUE, counts >= 2L & counts <= 20L)
  colors <- if (is.na(legend_index)) "#03F" else
    grDevices::hcl.colors(counts[[legend_index]], "Dark 3")

  ui <- shiny::fluidPage(
    shiny::titlePanel(spec$title),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        lapply(seq_along(filters), function(i) {
          choices <- filters[[i]]$choices
          shiny::selectInput(paste0("filter_", i), fields[[i]],
                             choices = choices, selected = unname(choices), multiple = TRUE)
        })
      ),
      shiny::mainPanel(
        leaflet::leafletOutput("map", height = 550),
        DT::DTOutput("attributes")
      )
    )
  )
  server <- function(input, output, session) {
    visible <- shiny::reactive({
      keep <- rep(TRUE, nrow(data))
      for (i in seq_along(filters)) {
        keep <- keep & filters[[i]]$value_ids %in% input[[paste0("filter_", i)]]
      }
      which(keep)
    })
    filtered <- shiny::reactive(data[visible(), ])
    output$map <- leaflet::renderLeaflet({
      d <- filtered()
      m <- leaflet::leaflet(options = leaflet::leafletOptions(preferCanvas = TRUE)) |>
        leaflet::addTiles()
      if (nrow(d) == 0L) return(m)
      labels <- popup_html(d, spec$popup_fields)
      feature_colors <- rep(colors[[1L]], nrow(d))
      if (!is.na(legend_index)) {
        filter <- filters[[legend_index]]
        ids <- filter$value_ids[visible()]
        feature_colors <- colors[ids]
        present <- sort(unique(ids))
        m <- leaflet::addLegend(m, position = "bottomright", colors = colors[present],
                                labels = htmltools::htmlEscape(names(filter$choices)[present]),
                                title = htmltools::htmlEscape(fields[[legend_index]]),
                                opacity = 1)
      }
      typ <- as.character(sf::st_geometry_type(d))
      points <- typ %in% c("POINT", "MULTIPOINT")
      lines <- typ %in% c("LINESTRING", "MULTILINESTRING")
      polygons <- typ %in% c("POLYGON", "MULTIPOLYGON")
      if (any(points)) {
        geometry <- sf::st_cast(sf::st_geometry(d)[points], "MULTIPOINT")
        point_data <- sf::st_sf(feature = which(points), geometry = geometry)
        point_data <- sf::st_cast(point_data, "POINT", warn = FALSE)
        m <- leaflet::addCircleMarkers(m, data = point_data,
                                       popup = labels[point_data$feature],
                                       color = feature_colors[point_data$feature],
                                       radius = 5)
      }
      if (any(lines)) {
        line_data <- sf::st_cast(sf::st_geometry(d)[lines], "MULTILINESTRING")
        m <- leaflet::addPolylines(m, data = line_data, popup = labels[lines],
                                  color = feature_colors[lines])
      }
      if (any(polygons)) {
        polygon_data <- sf::st_cast(sf::st_geometry(d)[polygons], "MULTIPOLYGON")
        m <- leaflet::addPolygons(m, data = polygon_data, popup = labels[polygons],
                                  color = feature_colors[polygons],
                                  fillOpacity = 0.5)
      }
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
      column <- attrs[[field]]
      val <- if (is.matrix(column)) column[i, ] else column[[i]]
      val <- paste(as.character(val), collapse = ", ")
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
