test_that("a GeoPackage can supply a named layer to the reader and app", {
  path <- tempfile(fileext = ".gpkg")
  on.exit(unlink(path))
  station <- sf::st_sf(station = "Central", geometry = sf::st_as_sfc(
    "POINT (-84.5 39.1)", crs = 4326
  ))
  roads <- sf::st_sf(road = "Main", geometry = sf::st_as_sfc(
    "LINESTRING (-84.5 39.1, -84.4 39.2)", crs = 4326
  ))
  sf::st_write(station, path, layer = "stations", quiet = TRUE)
  sf::st_write(sf::st_transform(roads, 3857), path, layer = "County roads", quiet = TRUE)

  default <- suppressWarnings(read_gis(path))
  expect_identical(default$station, "Central")
  selected <- read_gis(path, layer = "County roads")
  expect_identical(selected$road, "Main")
  expect_equal(sf::st_crs(selected), sf::st_crs(4326))
  expect_equal(sf::st_coordinates(selected), sf::st_coordinates(roads))
  expect_error(read_gis(path, layer = "absent"),
               "was not found.*Available layers:.*stations.*County roads")

  app <- gis2shiny(path, layer = "County roads", popup_fields = "road")
  expect_identical(app$data, selected)
  dest <- tempfile("geopackage-app-")
  on.exit(unlink(dest, recursive = TRUE), add = TRUE)
  export_app(app, dest)
  expect_identical(read_gis(file.path(dest, "data.gpkg"))$road, "Main")
  expect_type(shiny::shinyAppDir(dest)$serverFuncSource(), "closure")
})

test_that("layer arguments fail clearly for unsupported inputs", {
  d <- sf::st_sf(geometry = sf::st_as_sfc("POINT (0 0)", crs = 4326))
  for (bad in list("", NA_character_, character(), c("a", "b"), 1L)) {
    expect_error(read_gis("test.gpkg", layer = bad), "single nonempty layer name")
  }
  expect_error(read_gis(d, layer = "roads"), "only be used with a GeoPackage")
  expect_error(gis2shiny("file.geojson", layer = "roads"), "only be used with a GeoPackage")
})
