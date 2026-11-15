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
  attrs <- sf::st_drop_geometry(data)
  if (!is.character(title) || length(title) != 1L || is.na(title)) {
    stop("`title` must be a single character string.", call. = FALSE)
  }
  if (is.null(popup_fields)) popup_fields <- as.character(names(attrs))
  if (!is.character(popup_fields) || !all(popup_fields %in% names(attrs))) {
    stop("Unknown popup field(s). Supply a character vector of attribute names.",
         call. = FALSE)
  }
  eligible <- vapply(attrs, function(z) {
    is.atomic(z) && is.null(dim(z))
  }, logical(1))
  if (is.null(filter_fields)) {
    automatic <- vapply(attrs[eligible], function(z) {
      if (!(is.factor(z) || is.character(z) || is.logical(z))) return(FALSE)
      n_values <- length(unique(z[!is.na(z)]))
      n_values >= 2L && n_values <= 20L
    }, logical(1))
    filter_fields <- as.character(names(automatic)[automatic])
  }
  if (!is.character(filter_fields) || !all(filter_fields %in% names(attrs))) {
    stop("Unknown filter field(s). Supply a character vector of attribute names.",
         call. = FALSE)
  }
  if (!all(eligible[filter_fields])) {
    stop("Filter fields must contain one scalar value per feature.", call. = FALSE)
  }
  if (anyDuplicated(filter_fields)) stop("Duplicate filter fields.", call. = FALSE)
  structure(list(data = data, title = title,
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
