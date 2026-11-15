#' Export a standalone Shiny application
#'
#' Writes an `app.R` and a GeoPackage data file. The exported application
#' requires the `gis2shiny` package to be installed on its host.
#' @param app A `gis2shiny_app` specification.
#' @param path Destination directory; must not already contain files.
#' @return The destination path, invisibly.
#' @export
export_app <- function(app, path) {
  if (!inherits(app, "gis2shiny_app")) stop("Expected a gis2shiny_app.", call. = FALSE)
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    stop("`path` must be a nonempty directory path.", call. = FALSE)
  }
  if (dir.exists(path) && length(list.files(path, all.files = TRUE, no.. = TRUE))) {
    stop("Destination directory must be empty.", call. = FALSE)
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  sf::st_write(app$data, file.path(path, "data.gpkg"), quiet = TRUE)
  code <- c(
    "library(gis2shiny)",
    "data <- read_gis('data.gpkg')",
    paste0("app <- gis2shiny(data, title = ", deparse(app$title), ","),
    paste0("  popup_fields = ", paste(deparse(app$popup_fields), collapse = ""), ","),
    paste0("  filter_fields = ", paste(deparse(app$filter_fields), collapse = ""), ")"),
    "run_app(app)"
  )
  writeLines(code, file.path(path, "app.R"))
  invisible(path)
}
