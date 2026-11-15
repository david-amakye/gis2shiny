test_that("numeric style keeps ties together and marks missing values", {
  style <- numeric_map_style(c(1, 1, 2, 3, 4, 5, NA, Inf), "score")
  expect_identical(style$ids[1:2], c(1L, 1L))
  expect_equal(style$ids[7:8], rep(length(style$labels), 2L))
  expect_identical(tail(style$labels, 1L), "Missing or non-finite")
  expect_identical(tail(style$colors, 1L), "#767676")
  expect_identical(numeric_map_style(c(5, 5), "score")$labels, "5")

  skewed <- numeric_map_style(c(rep(10, 9), 1), "score")
  expect_identical(skewed$labels, c("<= 1", "> 1"))
  expect_identical(skewed$ids, c(rep(2L, 9), 1L))
})

test_that("numeric shading and legend keep a fixed scale under filtering", {
  d <- sf::st_as_sf(data.frame(score = c(1:5, NA), x = 1:6, y = 1:6),
                    coords = c("x", "y"), crs = 4326)
  spec <- gis2shiny(d, color_by = "score")
  style <- numeric_map_style(d$score, "score")
  color <- style$colors[style$ids[3L]]
  shiny::testServer(build_shiny_app(spec), {
    initial <- output$map
    expect_match(initial, "Missing or non-finite", fixed = TRUE)
    expect_match(initial, color, fixed = TRUE)
    session$setInputs(range_1_min = 3, range_1_max = 3, range_1_missing = FALSE)
    expect_match(output$map, color, fixed = TRUE)
    expect_match(output$map, "addLegend", fixed = TRUE)
    expect_false(grepl("Missing or non-finite", output$map, fixed = TRUE))
    expect_identical(filtered()$score, 3L)
  })
  expect_error(gis2shiny(d, color_by = "unknown"), "single attribute")
  d$non_numeric <- letters[1:6]
  expect_error(gis2shiny(d, color_by = "non_numeric"), "plain numeric")

  path <- tempfile("thematic-export-")
  on.exit(unlink(path, recursive = TRUE))
  export_app(spec, path)
  code <- parse(file.path(path, "app.R"))
  expect_identical(code[[3]][[3]][["color_by"]], "score")
  expect_type(shiny::shinyAppDir(path)$serverFuncSource(), "closure")
})
