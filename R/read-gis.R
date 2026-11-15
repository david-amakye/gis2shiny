#' Read vector GIS data
#'
#' @param x An `sf` object or a path to a Shapefile, GeoJSON, or GeoPackage.
#' @param layer Name of a GeoPackage layer, or `NULL` to read the first layer.
#'   Use `sf::st_layers(x)$name` to list layer names.
#' @details Every feature must have a nonempty, valid point, line, or polygon
#'   geometry (including multipart variants). Z and M coordinates are dropped
#'   for the two-dimensional map.
#' @return A validated `sf` object, transformed to EPSG:4326.
#' @export
read_gis <- function(x, layer = NULL) {
  if (!is.null(layer) &&
      (!is.character(layer) || length(layer) != 1L || is.na(layer) || !nzchar(layer))) {
    stop("`layer` must be a single nonempty layer name.", call. = FALSE)
  }
  if (!is.null(layer) &&
      (inherits(x, "sf") || !is.character(x) || length(x) != 1L || is.na(x) ||
       tolower(tools::file_ext(x)) != "gpkg")) {
    stop("`layer` can only be used with a GeoPackage path.", call. = FALSE)
  }
  if (inherits(x, "sf")) {
    data <- x
  } else if (is.character(x) && length(x) == 1L && !is.na(x)) {
    if (!file.exists(x)) stop("GIS file does not exist: ", x, call. = FALSE)
    if (dir.exists(x) || !tolower(tools::file_ext(x)) %in% c("shp", "geojson", "gpkg")) {
      stop("Expected a Shapefile (.shp), GeoJSON (.geojson), or GeoPackage (.gpkg).",
           call. = FALSE)
    }
    if (is.null(layer)) {
      data <- sf::st_read(x, quiet = TRUE)
    } else {
      available <- sf::st_layers(x)$name
      if (!layer %in% available) {
        stop("GeoPackage layer ", sQuote(layer), " was not found. Available layers: ",
             paste(sQuote(available), collapse = ", "), ".", call. = FALSE)
      }
      data <- sf::st_read(x, layer = layer, quiet = TRUE)
    }
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
  if (any(sf::st_is_empty(data))) {
    stop("Spatial data contains empty geometries.", call. = FALSE)
  }
  data <- sf::st_transform(sf::st_zm(data), 4326)
  if (any(sf::st_is_empty(data))) {
    stop("Transforming to EPSG:4326 produced empty geometries.", call. = FALSE)
  }
  valid <- sf::st_is_valid(data)
  if (anyNA(valid) || !all(valid)) {
    stop("Spatial data contains invalid geometries.", call. = FALSE)
  }
  data
}
