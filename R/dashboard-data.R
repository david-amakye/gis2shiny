# Numeric filter values and input IDs are shared by the UI and server.
numeric_filter <- function(column, field, index) {
  finite <- is.finite(column)
  ids <- paste0("range_", index, c("_min", "_max", "_missing"))
  list(field = field, values = column, finite = finite, ids = ids,
       bounds = range(column[finite]))
}

numeric_filter_ui <- function(filter) {
  bounds <- filter$bounds
  shiny::tags$fieldset(
    shiny::tags$legend(filter$field),
    shiny::fluidRow(
      shiny::column(6, shiny::numericInput(filter$ids[[1L]], "Minimum",
                                           sprintf("%.17g", bounds[[1L]]),
                                           step = "any", width = "100%")),
      shiny::column(6, shiny::numericInput(filter$ids[[2L]], "Maximum",
                                           sprintf("%.17g", bounds[[2L]]),
                                           step = "any", width = "100%"))
    ),
    if (!all(filter$finite)) {
      shiny::checkboxInput(filter$ids[[3L]], "Include missing and non-finite values",
                           value = TRUE)
    }
  )
}

in_numeric_range <- function(filter, inputs) {
  bounds <- filter$bounds
  for (i in seq_along(bounds)) {
    value <- inputs[[filter$ids[[i]]]]
    if (length(value) == 1L && is.finite(value)) bounds[[i]] <- value
  }
  keep <- filter$values >= bounds[[1L]] & filter$values <= bounds[[2L]]
  keep[!filter$finite] <- !identical(inputs[[filter$ids[[3L]]]], FALSE)
  keep
}

feature_attributes <- function(data, rows) {
  attrs <- sf::st_drop_geometry(data)
  if (!ncol(attrs)) return(data.frame(Feature = rows))
  attrs
}

attribute_text <- function(column, row) {
  value <- column[[row]]
  if (!is.null(dim(column))) {
    indices <- c(list(column, row), rep(list(TRUE), length(dim(column)) - 1L))
    value <- do.call(`[`, indices)
  }
  paste(as.character(value), collapse = ", ")
}

flat_attributes <- function(attrs) {
  for (name in names(attrs)) {
    column <- attrs[[name]]
    if (is.list(column) || !is.null(dim(column))) {
      attrs[[name]] <- vapply(seq_len(nrow(attrs)), function(row) {
        attribute_text(column, row)
      }, character(1))
    }
  }
  attrs
}

write_feature_geojson <- function(data, path) {
  attrs <- flat_attributes(sf::st_drop_geometry(data))
  for (name in names(attrs)) {
    column <- attrs[[name]]
    if (is.double(column) && !is.object(column)) {
      column[!is.finite(column)] <- NA_real_
      attrs[[name]] <- column
    }
  }
  geometry_name <- attr(data, "sf_column")
  attrs[[geometry_name]] <- sf::st_geometry(data)
  vector <- sf::st_as_sf(attrs, sf_column_name = geometry_name)
  sf::st_write(vector, path, driver = "GeoJSON", quiet = TRUE,
               layer_options = "RFC7946=YES")
}
