# gis2shiny 0.2.0

- Make the OpenStreetMap basemap optional and show a message when online tiles are unavailable.

- Select a named layer from a multi-layer GeoPackage with the `layer` argument.
- Shade maps by a numeric attribute with `color_by`. The legend bands stay consistent as the data is filtered.

# gis2shiny 0.1.0

- Validate supported vector inputs, reject empty and invalid geometries, and normalize coordinates for Leaflet.
- Render mixed and multipart geometries and preserve their feature popups.
- Validate filter fields and make exported projects launchable with `shiny::runApp()`.
- Color the map by the first filter field with 2 to 20 categories and show visible categories in a reactive legend.
- Include blank and missing values in categorical filters.
- Filter numeric attributes by inclusive ranges, with a separate option for missing and non-finite values.
- Summarize filtered features by geometry or category, and download matching rows as CSV or GeoJSON.
- Toggle geometry layers independently on mixed-geometry maps.
