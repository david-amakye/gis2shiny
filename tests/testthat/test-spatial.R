test_that("supported file formats and projected inputs are read", {
  shape <- system.file("shape/nc.shp", package = "sf", mustWork = TRUE)
  counties <- read_gis(shape)
  expect_equal(nrow(counties), 100L)
  expect_equal(sf::st_crs(counties), sf::st_crs(4326))

  roads <- sf::st_sf(name = "Road", geometry = sf::st_as_sfc(
    "LINESTRING (-84.5 39.1, -84.4 39.2)", crs = 4326
  ))
  for (ext in c(".geojson", ".gpkg")) {
    path <- tempfile(fileext = ext)
    sf::st_write(roads, path, quiet = TRUE)
    expect_equal(sf::st_geometry(read_gis(path)), sf::st_geometry(roads))
  }
  actual <- read_gis(sf::st_transform(roads, 3857))
  expect_equal(sf::st_coordinates(actual), sf::st_coordinates(roads))
  xyz <- sf::st_sf(geometry = sf::st_as_sfc("POINT Z (1 2 3)", crs = 4326))
  expect_equal(unname(sf::st_coordinates(read_gis(xyz))), matrix(c(1, 2), 1))
})

test_that("invalid input and geometry fail early", {
  geom <- function(wkt) sf::st_sf(geometry = sf::st_as_sfc(wkt, crs = 4326))
  path <- tempfile(fileext = ".csv")
  writeLines("x,y", path)
  expect_error(read_gis(path), "Expected a Shapefile")
  expect_error(read_gis(paste0(path, ".gpkg")), "does not exist")
  expect_error(read_gis(geom("POINT (1 2)")[FALSE, ]), "no features")
  expect_error(read_gis(geom(c("POINT (1 2)", "POINT EMPTY"))), "empty geometries")
  expect_error(read_gis(geom("GEOMETRYCOLLECTION (POINT (1 2))")), "Unsupported")
  expect_error(read_gis(geom("POLYGON ((0 0, 1 1, 0 1, 1 0, 0 0))")), "invalid")
})

test_that("all geometry families render together and filtering can yield no rows", {
  geometry <- sf::st_as_sfc(c(
    "POINT (0 0)", "MULTIPOINT ((1 2), (3 4))",
    "LINESTRING (0 0, 1 1)", "MULTILINESTRING ((0 0, 1 1), (2 2, 3 3))",
    "POLYGON ((0 0, 1 0, 1 1, 0 0))",
    "MULTIPOLYGON (((0 0, 1 0, 1 1, 0 0)))"
  ), crs = 4326)
  parcels <- sf::st_sf(group = rep(c("A", "B"), 3), geometry = geometry)
  app <- build_shiny_app(gis2shiny(parcels))
  shiny::testServer(app, {
    session$setInputs(filter_1 = c("A", "B"))
    expect_equal(nrow(filtered()), 6L)
    expect_match(output$map, "addCircleMarkers")
    expect_match(output$map, "addPolylines")
    expect_match(output$map, "addPolygons")
    expect_match(output$map, '0,2,4', fixed = TRUE)
    session$setInputs(filter_1 = character())
    expect_equal(nrow(filtered()), 0L)
    expect_match(output$map, "addTiles")
    expect_type(output$attributes, "character")
  })
})

test_that("filter and popup options handle non-scalar attributes", {
  d <- sf::st_sf(geometry = sf::st_as_sfc("POINT (1 2)", crs = 4326))
  d[["tags"]] <- list(c("<tag>", "other"))
  expect_error(gis2shiny(d, filter_fields = "missing"), "Unknown filter")
  expect_error(gis2shiny(d, filter_fields = "tags"), "scalar")
  expect_error(gis2shiny(d, title = NA_character_), "single character")
  expect_match(popup_html(d, "tags"), "&lt;tag&gt;, other", fixed = TRUE)
})
