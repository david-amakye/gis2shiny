# Internal Shiny application builder
build_shiny_app <- function(spec) {
  if (!inherits(spec, "gis2shiny_app")) stop("Expected a gis2shiny_app.", call. = FALSE)
  data <- spec$data
  geometry_types <- as.character(sf::st_geometry_type(data))
  families <- sub("^MULTI", "", geometry_types)
  group_names <- c(POINT = "Points", LINESTRING = "Lines", POLYGON = "Polygons")
  overlay_groups <- unname(group_names[names(group_names) %in% families])
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
  map_style <- NULL
  if (!is.null(spec$color_by)) {
    map_style <- numeric_map_style(data[[spec$color_by]], spec$color_by)
  } else if (!is.na(legend_index)) {
    category <- filters[[legend_index]]
    map_style <- list(field = fields[[legend_index]], ids = category$value_ids,
                      labels = names(category$choices), colors = colors)
  }
  ranges <- lapply(seq_along(spec$numeric_fields), function(i) {
    field <- spec$numeric_fields[[i]]
    numeric_filter(data[[field]], field, i)
  })
  summary_choices <- c("Geometry type" = "geometry")
  if (!is.na(legend_index)) {
    summary_choices <- c(summary_choices,
                         stats::setNames("category", fields[[legend_index]]))
  }

  ui <- shiny::fluidPage(
    shiny::titlePanel(spec$title),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        shiny::checkboxInput("online_basemap", "Show OpenStreetMap basemap", value = FALSE),
        lapply(seq_along(filters), function(i) {
          choices <- filters[[i]]$choices
          shiny::selectInput(paste0("filter_", i), fields[[i]],
                             choices = choices, selected = unname(choices), multiple = TRUE)
        }),
        if (length(ranges)) {
          shiny::tags$details(
            shiny::tags$summary("Numeric filters"),
            lapply(ranges, numeric_filter_ui)
          )
        }
      ),
      shiny::mainPanel(
        shiny::tags$div(id = "basemap_status", role = "status", hidden = NA,
                        "OpenStreetMap tiles are unavailable. Your GIS layers are still usable."),
        leaflet::leafletOutput("map", height = 550),
        shiny::tabsetPanel(
          shiny::tabPanel(
            "Attributes",
            DT::DTOutput("attributes"),
            shiny::downloadButton("download_csv", "Download CSV"),
            shiny::downloadButton("download_geojson", "Download GeoJSON")
          ),
          shiny::tabPanel(
            "Summary",
            shiny::textOutput("feature_count"),
            if (length(summary_choices) > 1L) {
              shiny::selectInput("summary_group", "Group by", choices = summary_choices)
            },
            shiny::plotOutput("summary_chart", height = "350px")
          )
        )
      )
    )
  )
  server <- function(input, output, session) {
    visible <- shiny::reactive({
      keep <- rep(TRUE, nrow(data))
      for (i in seq_along(filters)) {
        keep <- keep & filters[[i]]$value_ids %in% input[[paste0("filter_", i)]]
      }
      for (filter in ranges) {
        keep <- keep & in_numeric_range(filter, input)
      }
      which(keep)
    })
    filtered <- shiny::reactive(data[visible(), ])
    output$map <- leaflet::renderLeaflet({
      d <- filtered()
      m <- leaflet::leaflet(options = leaflet::leafletOptions(preferCanvas = TRUE))
      if (isTRUE(input$online_basemap)) {
        m <- leaflet::addTiles(m, "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                               attribution = paste0(
                                 '&copy; <a href="https://www.openstreetmap.org/copyright">',
                                 'OpenStreetMap contributors</a>'
                               ))
      }
      m <- htmlwidgets::onRender(m, '
        function(el) {
          const status = document.getElementById("basemap_status");
          status.hidden = true;
          const showFailure = function() { status.hidden = false; };
          if (!el.dataset.basemapErrorListener) {
            el.addEventListener("error", function(event) {
              if (event.target.matches("img.leaflet-tile")) showFailure();
            }, true);
            el.dataset.basemapErrorListener = "true";
          }
          el.querySelectorAll("img.leaflet-tile").forEach(function(tile) {
            if (tile.complete && !tile.naturalWidth) showFailure();
          });
        }
      ')
      if (length(overlay_groups) > 1L) {
        m <- leaflet::addLayersControl(m, overlayGroups = overlay_groups)
        shown <- shiny::isolate(input$map_groups)
        if (!is.null(shown)) {
          m <- leaflet::hideGroup(m, setdiff(overlay_groups, shown))
        }
      }
      if (nrow(d) == 0L) return(m)
      labels <- popup_html(d, spec$popup_fields)
      feature_colors <- rep("#03F", nrow(d))
      if (!is.null(map_style)) {
        ids <- map_style$ids[visible()]
        feature_colors <- map_style$colors[ids]
        present <- sort(unique(ids))
        m <- leaflet::addLegend(m, position = "bottomright",
                                colors = map_style$colors[present],
                                labels = htmltools::htmlEscape(map_style$labels[present]),
                                title = htmltools::htmlEscape(map_style$field),
                                opacity = 1)
      }
      typ <- families[visible()]
      points <- typ == "POINT"
      lines <- typ == "LINESTRING"
      polygons <- typ == "POLYGON"
      if (any(points)) {
        geometry <- sf::st_cast(sf::st_geometry(d)[points], "MULTIPOINT")
        point_data <- sf::st_sf(feature = which(points), geometry = geometry)
        point_data <- sf::st_cast(point_data, "POINT", warn = FALSE)
        m <- leaflet::addCircleMarkers(m, data = point_data,
                                       popup = labels[point_data$feature],
                                       color = feature_colors[point_data$feature], group = "Points",
                                       radius = 5)
      }
      if (any(lines)) {
        line_data <- sf::st_cast(sf::st_geometry(d)[lines], "MULTILINESTRING")
        m <- leaflet::addPolylines(m, data = line_data, popup = labels[lines],
                                  color = feature_colors[lines], group = "Lines")
      }
      if (any(polygons)) {
        polygon_data <- sf::st_cast(sf::st_geometry(d)[polygons], "MULTIPOLYGON")
        m <- leaflet::addPolygons(m, data = polygon_data, popup = labels[polygons],
                                  color = feature_colors[polygons], group = "Polygons",
                                  fillOpacity = 0.5)
      }
      bbox <- sf::st_bbox(d)
      if (all(is.finite(bbox))) {
        m <- leaflet::fitBounds(m, lng1 = unname(bbox["xmin"]), lat1 = unname(bbox["ymin"]),
                                lng2 = unname(bbox["xmax"]), lat2 = unname(bbox["ymax"]))
      }
      m
    })
    attributes <- shiny::reactive(feature_attributes(filtered(), visible()))
    output$attributes <- DT::renderDT({
      DT::datatable(attributes(), options = list(pageLength = 10), rownames = FALSE)
    })
    summary_data <- shiny::reactive({
      if (identical(input$summary_group, "category") && !is.na(legend_index)) {
        filter <- filters[[legend_index]]
        counts <- tabulate(filter$value_ids[visible()], nbins = length(filter$choices))
        present <- which(counts > 0L)
        return(list(labels = names(filter$choices)[present], counts = counts[present],
                    colors = colors[present]))
      }
      counts <- table(geometry_types[visible()])
      list(labels = names(counts), counts = as.integer(counts), colors = "#03F")
    })
    output$feature_count <- shiny::renderText({
      paste(format(nrow(filtered()), big.mark = ","), "features")
    })
    output$summary_chart <- shiny::renderPlot({
      summary <- summary_data()
      shiny::validate(shiny::need(length(summary$counts) > 0L, "No features match the filters."))
      labels <- ifelse(nchar(summary$labels) > 24L,
                       paste0(substr(summary$labels, 1L, 21L), "..."), summary$labels)
      margin <- max(6, max(nchar(labels)) * 0.55)
      graphics::par(mar = c(4, margin, 1, 1))
      graphics::barplot(rev(summary$counts), names.arg = rev(labels), horiz = TRUE,
                        col = rev(summary$colors), border = NA, las = 1,
                        xlab = "Features")
    }, alt = function() {
      summary <- summary_data()
      paste(paste0(summary$labels, ": ", summary$counts), collapse = ". ")
    })
    output$download_csv <- shiny::downloadHandler(
      filename = "features.csv",
      contentType = "text/csv",
      content = function(path) {
        utils::write.csv(flat_attributes(attributes()), path, row.names = FALSE,
                         fileEncoding = "UTF-8")
      }
    )
    output$download_geojson <- shiny::downloadHandler(
      filename = "features.geojson",
      contentType = "application/geo+json",
      content = function(path) write_feature_geojson(filtered(), path)
    )
  }
  shiny::shinyApp(ui, server)
}

popup_html <- function(data, fields) {
  if (length(fields) == 0L) return(rep("Feature", nrow(data)))
  attrs <- sf::st_drop_geometry(data)
  vapply(seq_len(nrow(attrs)), function(i) {
    paste(vapply(fields, function(field) {
      val <- attribute_text(attrs[[field]], i)
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
