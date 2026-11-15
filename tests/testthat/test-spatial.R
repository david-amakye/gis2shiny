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
    session$setInputs(filter_1 = c("1", "2"))
    expect_equal(nrow(filtered()), 6L)
    expect_match(output$map, "addCircleMarkers")
    expect_match(output$map, "addPolylines")
    expect_match(output$map, "addPolygons")
    expect_match(output$map, "addLegend")
    expect_match(output$map, "addLayersControl")
    expect_match(output$map, '0,2,4', fixed = TRUE)
    session$setInputs(filter_1 = character())
    expect_equal(nrow(filtered()), 0L)
    expect_false(grepl("addTiles", output$map, fixed = TRUE))
    session$setInputs(online_basemap = TRUE)
    expect_match(output$map, "addTiles", fixed = TRUE)
    expect_match(output$map, "https://tile.openstreetmap.org/", fixed = TRUE)
    expect_match(output$map, "OpenStreetMap contributors", fixed = TRUE)
    session$setInputs(online_basemap = FALSE)
    expect_false(grepl("addTiles", output$map, fixed = TRUE))
    expect_false(grepl("addLegend", output$map, fixed = TRUE))
    expect_type(output$attributes, "character")
  })
})

test_that("legend colors stay stable and filter choices include blank and missing values", {
  d <- sf::st_as_sf(data.frame(x = 1:4, y = 1:4,
    `Status <type>` = c("", "<img onerror=x>", "Open", NA_character_),
    check.names = FALSE
  ), coords = c("x", "y"), crs = 4326)
  app <- build_shiny_app(gis2shiny(d))
  values <- sort(d[["Status <type>"]], na.last = TRUE)
  open_id <- match("Open", values)
  color <- grDevices::hcl.colors(4L, "Dark 3")[[open_id]]
  shiny::testServer(app, {
    session$setInputs(filter_1 = as.character(seq_along(values)))
    expect_equal(nrow(filtered()), 4L)
    expect_match(output$map, "Status &lt;type&gt;", fixed = TRUE)
    expect_match(output$map, "&lt;img onerror=x&gt;", fixed = TRUE)
    expect_match(output$map, color, fixed = TRUE)
    session$setInputs(filter_1 = as.character(open_id))
    expect_identical(filtered()[["Status <type>"]], "Open")
    expect_match(output$map, color, fixed = TRUE)
    expect_false(grepl("&lt;img", output$map, fixed = TRUE))
    session$setInputs(filter_1 = as.character(match("", values)))
    expect_identical(filtered()[["Status <type>"]], "")
    session$setInputs(filter_1 = as.character(match(NA_character_, values)))
    expect_identical(filtered()[["Status <type>"]], NA_character_)
  })
})

test_that("automatic filters distinguish a missing value from its label", {
  d <- sf::st_as_sf(data.frame(x = 1:2, y = 1:2,
    status = c("(missing)", NA_character_)
  ), coords = c("x", "y"), crs = 4326)
  spec <- gis2shiny(d)
  expect_identical(spec$filter_fields, "status")
  shiny::testServer(build_shiny_app(spec), {
    session$setInputs(filter_1 = "1")
    expect_identical(filtered()$status, "(missing)")
    session$setInputs(filter_1 = "2")
    expect_identical(filtered()$status, NA_character_)
    expect_match(output$map, "(missing) 1", fixed = TRUE)
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
