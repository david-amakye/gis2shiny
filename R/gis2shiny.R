#' Create a GIS-to-Shiny application specification
#'
#' @param x An `sf` object or vector GIS file path.
#' @param title Application title.
#' @param popup_fields Character vector of fields to show in popups, or `NULL`
#'   for all non-geometry fields.
#' @param filter_fields Character vector of categorical fields to filter, or
#'   `NULL` to automatically select suitable fields.
#' @return A `gis2shiny_app` object.
#' @export
#' @examples
#' app <- gis2shiny(sf::st_as_sf(data.frame(x = -84.5, y = 39.1),
#'   coords = c("x", "y"), crs = 4326))
#' print(app)
gis2shiny <- function(x, title = "GIS Explorer", popup_fields = NULL,
                      filter_fields = NULL) {
  data <- read_gis(x)
  attrs <- names(sf::st_drop_geometry(data))
  if (is.null(popup_fields)) popup_fields <- attrs
  if (!all(popup_fields %in% attrs)) stop("Unknown popup field(s).", call. = FALSE)
  if (is.null(filter_fields)) {
    eligible <- vapply(sf::st_drop_geometry(data), function(z) {
      (is.factor(z) || is.character(z) || is.logical(z)) &&
        length(unique(z[!is.na(z)])) >= 2L &&
        length(unique(z[!is.na(z)])) <= 20L
    }, logical(1))
    filter_fields <- names(eligible)[eligible]
  }
  if (!all(filter_fields %in% attrs)) stop("Unknown filter field(s).", call. = FALSE)
  if (anyDuplicated(filter_fields)) stop("Duplicate filter fields.", call. = FALSE)
  structure(list(data = data, title = as.character(title)[1L],
                 popup_fields = popup_fields, filter_fields = filter_fields),
            class = "gis2shiny_app")
}

#' @export
print.gis2shiny_app <- function(x, ...) {
  cat("<gis2shiny_app>", x$title, "\n")
  cat("Features:", nrow(x$data), "\n")
  cat("Filters:", paste(x$filter_fields, collapse = ", "), "\n")
  invisible(x)
}
