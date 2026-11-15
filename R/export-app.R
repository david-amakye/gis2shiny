#' Export an editable Shiny application
#'
#' Writes an `app.R` and a GeoPackage data file. The exported application
#' requires the `gis2shiny` package to be installed on its host.
#' Start the exported project with `shiny::runApp(path)`.
#' @param app A `gis2shiny_app` specification.
#' @param path Destination directory; must not already contain files.
#' @return The destination path, invisibly.
#' @export
export_app <- function(app, path) {
  if (!inherits(app, "gis2shiny_app")) stop("Expected a gis2shiny_app.", call. = FALSE)
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    stop("`path` must be a nonempty directory path.", call. = FALSE)
  }
  if (!dir.exists(path) && !dir.create(path, recursive = TRUE, showWarnings = FALSE)) {
    stop("Cannot create destination directory: ", path, call. = FALSE)
  }
  staging <- file.path(path, ".gis2shiny-export")
  if (!dir.create(staging, showWarnings = FALSE)) {
    stop("Cannot stage export in destination directory: ", path, call. = FALSE)
  }
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  if (length(setdiff(list.files(path, all.files = TRUE, no.. = TRUE),
                     basename(staging)))) {
    stop("Destination directory must be empty.", call. = FALSE)
  }
  data_file <- file.path(path, "data.gpkg")
  app_file <- file.path(path, "app.R")
  staged_data <- file.path(staging, basename(data_file))
  staged_app <- file.path(staging, basename(app_file))
  attrs <- names(sf::st_drop_geometry(app$data))
  # Reserve names without shadowing attributes in the GeoPackage schema.
  reserved <- make.unique(c(tolower(attrs), "fid", "geom"))
  columns <- utils::tail(reserved, 2L)
  sf::st_write(app$data, staged_data, quiet = TRUE,
               layer_options = paste0(c("FID=", "GEOMETRY_NAME="), columns))
  exported_attrs <- names(sf::st_drop_geometry(sf::st_read(staged_data, quiet = TRUE)))
  if (!identical(as.character(attrs), as.character(exported_attrs))) {
    stop("GeoPackage export could not preserve the attribute columns.", call. = FALSE)
  }
  literal <- function(value) {
    if (!length(value)) return("character(0)")
    quoted <- encodeString(enc2utf8(value), quote = '"')
    if (length(quoted) == 1L) return(quoted)
    paste0("c(", paste(quoted, collapse = ",\n    "), ")")
  }
  code <- c(
    "library(gis2shiny)",
    "data <- read_gis('data.gpkg')",
    paste0("app <- gis2shiny(data, title = ", literal(app$title), ","),
    paste0("  popup_fields = ", literal(app$popup_fields), ","),
    paste0("  filter_fields = ", literal(app$filter_fields), ","),
    paste0("  numeric_fields = ", literal(app$numeric_fields),
           if (is.null(app$color_by)) ")" else ","),
    if (!is.null(app$color_by)) paste0("  color_by = ", literal(app$color_by), ")"),
    "gis2shiny:::build_shiny_app(app)"
  )
  writeLines(code, staged_app, useBytes = TRUE)
  if (!file.rename(staged_data, data_file)) {
    stop("Cannot publish data.gpkg in the destination directory.", call. = FALSE)
  }
  if (!file.rename(staged_app, app_file)) {
    unlink(data_file)
    stop("Cannot publish app.R in the destination directory.", call. = FALSE)
  }
  invisible(path)
}
