#' Create a GIS-to-Shiny application specification
#'
#' @param x An `sf` object or vector GIS file path.
#' @param title Application title.
#' @param popup_fields Character vector of fields to show in popups, or `NULL`
#'   for all non-geometry fields.
#' @param filter_fields Character vector of categorical fields to filter, or
#'   `NULL` to automatically select suitable fields.
#' @param numeric_fields Character vector of fields to filter by inclusive
#'   numeric ranges. Use `NULL` to choose varying plain numeric fields
#'   automatically or `character(0)` to disable numeric filters.
#' @inheritParams read_gis
#' @details Filters start with all categories selected, including blank and
#'   missing values where present. The first filter field with 2 to 20
#'   categories determines the map colors. The legend shows categories in
#'   the filtered map while keeping their colors consistent across selections.
#'   Numeric ranges start at the observed bounds. Missing and non-finite
#'   values can be included separately. The map, table, summaries, and
#'   downloads use the same filtered features.
#' @return A `gis2shiny_app` object.
#' @export
#' @examples
#' app <- gis2shiny(sf::st_as_sf(data.frame(x = -84.5, y = 39.1),
#'   coords = c("x", "y"), crs = 4326))
#' print(app)
gis2shiny <- function(x, title = "GIS Explorer", popup_fields = NULL,
                      filter_fields = NULL, numeric_fields = NULL, layer = NULL) {
  data <- read_gis(x, layer = layer)
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
      n_values <- length(unique(z))
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
  numeric_candidates <- vapply(attrs, function(column) {
    typeof(column) %in% c("integer", "double") && !is.object(column) &&
      is.null(dim(column)) &&
      any(is.finite(column))
  }, logical(1))
  if (is.null(numeric_fields)) {
    automatic <- vapply(attrs[numeric_candidates], function(column) {
      length(unique(column[is.finite(column)])) >= 2L
    }, logical(1))
    numeric_fields <- setdiff(as.character(names(automatic)[automatic]), filter_fields)
  }
  if (!is.character(numeric_fields) || !all(numeric_fields %in% names(attrs))) {
    stop("Unknown numeric field(s). Supply a character vector of attribute names.",
         call. = FALSE)
  }
  if (!all(numeric_candidates[numeric_fields])) {
    stop("Numeric fields must contain plain numeric values with at least one finite value.",
         call. = FALSE)
  }
  if (anyDuplicated(numeric_fields)) stop("Duplicate numeric fields.", call. = FALSE)
  if (length(intersect(filter_fields, numeric_fields))) {
    stop("A field can have either a categorical filter or a numeric range.", call. = FALSE)
  }
  structure(list(data = data, title = title,
                 popup_fields = popup_fields, filter_fields = filter_fields,
                 numeric_fields = numeric_fields),
            class = "gis2shiny_app")
}

#' @export
print.gis2shiny_app <- function(x, ...) {
  cat("<gis2shiny_app>", x$title, "\n")
  cat("Features:", nrow(x$data), "\n")
  cat("Filters:", paste(c(x$filter_fields, x$numeric_fields), collapse = ", "), "\n")
  invisible(x)
}
