# BC Land Cover Change Shiny App
 
An R Shiny application for visualizing BC land cover across Wildlife Management Units (WMUs).
 
## Overview
 
The **BC Land Cover Change Shiny App** is an interactive visualization tool for exploring land cover dynamics across British Columbia Wildlife Management Units (WMUs) from **1984–2022**.
 
The application allows users to:
 
- Examine temporal trends in land cover
- Compare multiple land cover classes
- Visualize spatial patterns across WMUs
- Download summarized datasets for further analysis
 
The app combines annual land cover datasets with WMU boundary information to provide both statistical and spatial perspectives on landscape change.
 
---
 
## Features
 
### Land Cover Filtering
 
Users can:
 
- Select one or more land cover classes
- Filter results by Wildlife Management Unit (WMU)
- Restrict analyses to a custom range of years
 
Display results as:
 
- **Percent Cover (%)**
- **Area (hectares)**
 
---
 
## Figures & Table
 
The **Figures & Table** tab includes:
 
### Time Series Plot
 
Displays annual trends in selected land cover classes.
 
**Options:**
 
- Multiple classes displayed simultaneously
- Optional 3-year moving average smoothing
 
### Annual Bar Chart
 
Displays yearly land cover values as grouped bars.
 
### Data Table
 
Provides the summarized data used in the visualizations.
 
### Data Download
 
Users can export the currently filtered table as a CSV file.
 
---
 
## Interactive Mapping
 
The **Mapping** tab displays WMUs colored according to average land cover area.
 
### Popups provide
 
- WMU identifier
- Total WMU area (ha)
- Average land cover area across the selected period
- Average land cover percentage across the selected period
 
### Map Features
 
- Interactive zoom and pan
- WMU polygon highlighting
- Continuous color legend
 
---
 
## Time Series Mapping
 
The **Time Series Mapping** tab provides faceted maps showing annual land cover values through time.
 
### Features
 
- One map panel per year
- Spatial visualization of temporal change
- Viridis color scale for quantitative comparison
 
---
 
## Data Requirements
 
The application expects the following files in a `data/` directory:
 
| File | Description |
|------|-------------|
| `lc_class_year.rds` | Land cover observations by class, year, and WMU |
| `lc_wide.rds` | Wide-format land cover dataset |
| `lc_yearly.rds` | Annual land cover summaries |
| `wmu_labels.rds` | WMU labels and metadata |
| `wmus_leaflet.rds` | WMU spatial polygons for mapping |
| `lc_avg.rds` | Average land cover summaries |
 
### Directory Structure
 
```text
project/
├── app.R
└── data/
    ├── lc_class_year.rds
    ├── lc_wide.rds
    ├── lc_yearly.rds
    ├── wmu_labels.rds
    ├── wmus_leaflet.rds
    └── lc_avg.rds
```
 
---
 
## Installation
 
### Prerequisites
 
- R (≥ 4.2 recommended)
 
### Required Packages
 
```r
install.packages(c(
  "shiny",
  "dplyr",
  "tidyr",
  "data.table",
  "ggplot2",
  "sf",
  "leaflet",
  "DT",
  "shinyWidgets"
))
```
 
---
 
## Running the Application
 
Open `app.R` in RStudio and run:
 
```r
shiny::runApp()
```
 
Alternatively:
 
```r
source("app.R")
```
 
The application will launch in your default web browser.
 
---
 
## Data Structure
 
The primary dataset (`lc_class_year.rds`) should contain at minimum:
 
| Field | Description |
|---------|-------------|
| `unit_id` | Wildlife Management Unit identifier |
| `year` | Observation year |
| `class_name` | Land cover class |
| `area_ha` | Area in hectares |
| `pct` | Percent cover |
 
---
 
## Workflow
 
1. Select one or more land cover classes.
2. Optionally filter by WMU(s).
3. Select a year range.
4. Choose a metric:
   - Percent Cover
   - Area (ha)
5. Explore:
   - Trend plots
   - Annual summaries
   - Interactive maps
   - Time-series maps
6. Download filtered results as CSV.
 
---
 
## Outputs
 
### Visual Outputs
 
- Multi-class time series plots
- Annual grouped bar charts
- Interactive WMU maps
- Annual faceted spatial maps
 
### Downloadable Outputs
 
- Filtered summary table (`.csv`)
 
---
 
## Notes
 
- The smoothing option applies a centered 3-year moving average.
- Spatial calculations assume WMU geometries are stored as valid `sf` objects.
- WMU areas displayed in map popups are calculated directly from polygon geometry.
- Missing data are automatically excluded from visualizations where appropriate.
 
---
 
## Author
 
**Michael Li**
 
Special thanks to:
 
- Luke Vander Vennen
- Garth Mowat
- Joanna Burgar
 
---
 
## License
 
**CC BY 4.0**
 
This work is licensed under the Creative Commons Attribution 4.0 International License.
