test_that("sf data produces an application specification", {
  d <- sf::st_as_sf(data.frame(name = c("A", "B"), lon = c(-84.5, -84.4), lat = c(39.1, 39.2)),
                    coords = c("lon", "lat"), crs = 4326)
  a <- gis2shiny(d)
  expect_s3_class(a, "gis2shiny_app")
  expect_equal(nrow(a$data), 2L)
  expect_true("name" %in% a$filter_fields)
})

test_that("missing CRS is rejected", {
  d <- sf::st_as_sf(data.frame(lon = -84.5, lat = 39.1), coords = c("lon", "lat"))
  expect_error(read_gis(d), "defined CRS")
})

test_that("popup HTML escapes untrusted attributes", {
  d <- sf::st_as_sf(data.frame(name = "<script>alert(1)</script>", lon = -84.5, lat = 39.1),
                    coords = c("lon", "lat"), crs = 4326)
  html <- gis2shiny:::popup_html(d, "name")
  expect_false(grepl("<script>", html, fixed = TRUE))
})

test_that("export creates application files", {
  d <- sf::st_as_sf(data.frame(name = c("A", "B"), lon = c(-84.5, -84.4), lat = c(39.1, 39.2)),
                    coords = c("lon", "lat"), crs = 4326)
  dest <- tempfile("gis2shiny-")
  export_app(gis2shiny(d), dest)
  expect_true(file.exists(file.path(dest, "app.R")))
  expect_true(file.exists(file.path(dest, "data.gpkg")))
})
