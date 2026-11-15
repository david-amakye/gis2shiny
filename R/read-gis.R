#' Read vector GIS data
#'
#' @param x An `sf` object or a path to a vector GIS file.
#' @return A validated `sf` object, transformed to EPSG:4326.
#' @export
read_gis <- function(x) {
  if (inherits(x, "sf")) {
    data <- x
  } else if (is.character(x) && length(x) == 1L && !is.na(x)) {
    if (!file.exists(x)) stop("GIS file does not exist: ", x, call. = FALSE)
    data <- sf::st_read(x, quiet = TRUE)
  } else {
    stop("`x` must be an sf object or a single GIS file path.", call. = FALSE)
  }
  if (!inherits(data, "sf")) stop("Input is not an sf object.", call. = FALSE)
  if (nrow(data) == 0L) stop("Spatial data contains no features.", call. = FALSE)
  if (is.na(sf::st_crs(data))) stop("Spatial data must have a defined CRS.", call. = FALSE)
  types <- unique(as.character(sf::st_geometry_type(data)))
  supported <- c("POINT", "MULTIPOINT", "LINESTRING", "MULTILINESTRING",
                 "POLYGON", "MULTIPOLYGON")
  if (!all(types %in% supported)) {
    stop("Unsupported geometry type(s): ", paste(setdiff(types, supported), collapse = ", "),
         call. = FALSE)
  }
  sf::st_transform(data, 4326)
}
