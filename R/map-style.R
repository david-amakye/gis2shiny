numeric_map_style <- function(values, field) {
  finite <- is.finite(values)
  observed <- values[finite]
  # Use observed cut points so duplicate values always receive the same color.
  breaks <- unique(stats::quantile(observed, seq(0.2, 0.8, by = 0.2),
                                  type = 1L, names = FALSE))
  breaks <- breaks[breaks < max(observed)]
  if (!length(breaks) && min(observed) < max(observed)) {
    breaks <- min(observed)
  }
  format_breaks <- function(x) {
    labels <- format(x, digits = 15, trim = TRUE, decimal.mark = ".")
    ifelse(as.numeric(labels) == x, labels, sprintf("%.17g", x))
  }
  if (length(breaks)) {
    limits <- format_breaks(breaks)
    labels <- c(paste("<=", limits[[1L]]),
                if (length(limits) > 1L) {
                  paste(utils::head(limits, -1L), "< value <=", limits[-1L])
                },
                paste(">", utils::tail(limits, 1L)))
  } else {
    labels <- format_breaks(observed[[1L]])
  }
  colors <- grDevices::hcl.colors(length(labels), palette = "YlGnBu", rev = TRUE)
  ids <- integer(length(values))
  ids[finite] <- findInterval(values[finite], breaks, left.open = TRUE) + 1L
  if (any(!finite)) {
    labels <- c(labels, "Missing or non-finite")
    colors <- c(colors, "#767676")
    ids[!finite] <- length(labels)
  }
  list(field = field, ids = ids, labels = labels, colors = colors)
}
