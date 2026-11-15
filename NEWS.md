# gis2shiny 0.1.0 (in development)

- Validate supported vector inputs, reject empty and invalid geometries, and normalize coordinates for Leaflet.
- Render mixed and multipart geometries and preserve their feature popups.
- Validate filter fields and make exported projects launchable with `shiny::runApp()`.
- Color the map by the first filter field with 2 to 20 categories and show visible categories in a reactive legend.
- Include blank and missing values in categorical filters.
- Filter numeric attributes by inclusive ranges, with a separate option for missing and non-finite values.
- Summarize filtered features by geometry or category, and download matching rows as CSV or GeoJSON.
- Toggle geometry layers independently on mixed-geometry maps.
