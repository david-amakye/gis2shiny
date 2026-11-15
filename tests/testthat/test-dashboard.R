dashboard_points <- function() {
  sf::st_as_sf(data.frame(
    name = c("One", "Two", "Three", "Four", "Five"),
    group = c("A", "A", "B", "A", "B"),
    score = c(-4.5, 2.25, 4, NA, Inf),
    constant = 10,
    date = as.Date("2026-01-01") + 1:5,
    x = 1:5,
    y = 1:5
  ), coords = c("x", "y"), crs = 4326)
}

test_that("numeric fields are inferred and explicitly configurable", {
  d <- dashboard_points()
  expect_identical(gis2shiny(d)$numeric_fields, "score")
  expect_identical(gis2shiny(d, numeric_fields = character())$numeric_fields,
                   character())
  expect_identical(gis2shiny(d, numeric_fields = "constant")$numeric_fields,
                   "constant")
  expect_identical(gis2shiny(d, filter_fields = "score")$numeric_fields,
                   character())
  expect_error(gis2shiny(d, numeric_fields = "date"), "plain numeric")
  expect_error(gis2shiny(d, numeric_fields = "absent"), "Unknown numeric")
  expect_error(gis2shiny(d, numeric_fields = c("score", "score")), "Duplicate numeric")
  expect_error(gis2shiny(d, filter_fields = "score", numeric_fields = "score"),
               "either a categorical filter or a numeric range")
})

test_that("numeric and categorical controls drive the same summaries and downloads", {
  spec <- gis2shiny(dashboard_points(), filter_fields = "group")
  shiny::testServer(build_shiny_app(spec), {
    session$setInputs(filter_1 = c("1", "2"))
    expect_equal(nrow(filtered()), 5L)
    exported <- sf::st_read(output$download_geojson, quiet = TRUE)
    expect_identical(is.na(exported$score), c(FALSE, FALSE, FALSE, TRUE, TRUE))
    session$setInputs(filter_1 = "1", range_1_min = 2.25, range_1_max = 2.25,
                      range_1_missing = FALSE, summary_group = "category")
    expect_identical(filtered()$name, "Two")
    expect_identical(summary_data()$labels, "A")
    expect_identical(summary_data()$counts, 1L)
    expect_match(output$map, "Two", fixed = TRUE)
    expect_identical(utils::read.csv(output$download_csv)$name, "Two")
    expect_identical(sf::st_read(output$download_geojson, quiet = TRUE)$name, "Two")
    session$setInputs(range_1_missing = TRUE, summary_group = "geometry")
    expect_identical(filtered()$name, c("Two", "Four"))
    expect_identical(summary_data()$labels, "POINT")
    expect_identical(summary_data()$counts, 2L)
    session$setInputs(range_1_min = 100, range_1_missing = FALSE)
    expect_equal(nrow(filtered()), 0L)
    expect_length(summary_data()$counts, 0L)
    expect_equal(nrow(utils::read.csv(output$download_csv)), 0L)
    expect_equal(nrow(sf::st_read(output$download_geojson, quiet = TRUE)), 0L)
  })
})

test_that("numeric controls preserve the initial bounds at double precision", {
  values <- c(1 + .Machine$double.eps, 1 + 8 * .Machine$double.eps)
  filter <- numeric_filter(values, "value", 1L)
  expect_match(as.character(numeric_filter_ui(filter)),
               'value="1.0000000000000002"', fixed = TRUE)
  expect_match(as.character(numeric_filter_ui(filter)),
               'value="1.0000000000000018"', fixed = TRUE)
})

test_that("geometry-only downloads use stable row IDs for attributes", {
  d <- sf::st_sf(geometry = sf::st_as_sfc(c("POINT (1 1)", "POINT (2 2)"),
                                           crs = 4326))
  shiny::testServer(build_shiny_app(gis2shiny(d)), {
    expect_identical(utils::read.csv(output$download_csv)$Feature, 1:2)
    expect_equal(nrow(sf::st_read(output$download_geojson, quiet = TRUE)), 2L)
  })
})

test_that("exported projects retain selected numeric fields", {
  d <- dashboard_points()
  d$score[!is.finite(d$score)] <- NA_real_
  path <- tempfile("dashboard-")
  on.exit(unlink(path, recursive = TRUE))
  export_app(gis2shiny(d, numeric_fields = "constant"), path)
  code <- parse(file.path(path, "app.R"), encoding = "UTF-8")
  expect_identical(code[[3]][[3]][["numeric_fields"]], "constant")
  expect_type(shiny::shinyAppDir(path)$serverFuncSource(), "closure")
})
