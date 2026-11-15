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
  d$fid <- c(14L, 28L)
  d$geom <- c("x", "y")
  on.exit(unlink(dest, recursive = TRUE))
  title <- paste0("Caf\u00e9 \"Explorer\" ", strrep("a", 100))
  export_app(gis2shiny(d, title = title), dest)
  expect_true(file.exists(file.path(dest, "app.R")))
  expect_true(file.exists(file.path(dest, "data.gpkg")))
  expect_error(export_app(gis2shiny(d), dest), "must be empty")
  exported_data <- read_gis(file.path(dest, "data.gpkg"))
  expect_identical(sf::st_drop_geometry(exported_data), sf::st_drop_geometry(d))
  exported <- shiny::shinyAppDir(dest)
  expect_s3_class(exported, "shiny.appobj")
  expect_type(exported$serverFuncSource(), "closure")
  code <- parse(file.path(dest, "app.R"), encoding = "UTF-8")
  expect_identical(code[[3]][[3]][["title"]], title)
})

test_that("GeoPackage export cleans up when an attribute cannot be written", {
  d <- sf::st_sf(geometry = sf::st_as_sfc("POINT (1 2)", crs = 4326))
  d[["tags"]] <- list(c("first", "second"))
  dest <- tempfile("gis2shiny-")
  on.exit(unlink(dest, recursive = TRUE))
  expect_error(suppressWarnings(export_app(gis2shiny(d), dest)))
  expect_length(list.files(dest, all.files = TRUE, no.. = TRUE), 0L)
})
