############################################################
# BC LAND COVER CHANGE SHINY APP - DOWNLOAD ENABLED
############################################################

options(shiny.maxRequestSize = 30*1024^2)

suppressPackageStartupMessages({
  library(shiny)
  library(dplyr)
  library(tidyr)
  library(data.table)
  library(ggplot2)
  library(sf)
  library(leaflet)
  library(DT)
  library(shinyWidgets)
})

# Auto-set working directory
if(requireNamespace("rstudioapi", quietly = TRUE) &&
   rstudioapi::isAvailable()){
  current_file <- rstudioapi::getActiveDocumentContext()$path
  if(nchar(current_file) > 0) setwd(dirname(current_file))
}

############################################################
# LOAD DATA
############################################################

data_dir <- "data"
data_files <- c(
  "lc_class_year.rds",
  "lc_wide.rds",
  "lc_yearly.rds",
  "wmu_labels.rds",
  "wmus_leaflet.rds",
  "lc_avg.rds"
)
for(f in data_files){
  full_path <- file.path(data_dir, f)
  if(!file.exists(full_path)) stop("Missing file: ", full_path)
}

lc      <- readRDS(file.path(data_dir,"lc_class_year.rds"))
lc_wide <- readRDS(file.path(data_dir,"lc_wide.rds"))
lc_yearly <- readRDS(file.path(data_dir,"lc_yearly.rds"))
labels  <- readRDS(file.path(data_dir,"wmu_labels.rds"))
wmus    <- readRDS(file.path(data_dir,"wmus_leaflet.rds"))
lc_avg  <- readRDS(file.path(data_dir,"lc_avg.rds"))

setDT(lc)
classes <- sort(unique(lc$class_name))
minyear <- min(lc$year, na.rm = TRUE)
maxyear <- max(lc$year, na.rm = TRUE)

############################################################
# UI
############################################################

ui <- navbarPage(
  title = "B.C. Land Cover Change",
  tabPanel(
    "App",
    sidebarLayout(
      sidebarPanel(
        pickerInput(
          "classInput","Land Cover Class",
          choices = classes,
          multiple = TRUE,
          options = pickerOptions(
            actionsBox = TRUE,
            liveSearch = TRUE,
            noneSelectedText = "Select Land Cover Class")
        ),
        pickerInput(
          "unitsInput","WMUs",
          choices = setNames(
            labels$WILDLIFE_M,
            paste(labels$WILDLIFE_M,
                  labels$REGION_R_1,
                  labels$GAME_MAN_1,
                  sep = ", ")
          ),
          multiple = TRUE,
          options = pickerOptions(
            actionsBox = TRUE,
            liveSearch = TRUE,
            noneSelectedText = "Select WMUs")
        ),
        sliderInput(
          "yearsInput","Years",
          min = minyear,
          max = maxyear,
          value = c(minyear,maxyear),
          sep = ""
        ),
        selectInput(
          "metricInput","Metric",
          choices = c("Percent Cover","Area (ha)")
        ),
        conditionalPanel(
          condition = "input.tabInput=='Figures & Table'",
          checkboxInput("smoothInput",
                        "Smoothed (3-year moving average)"),
          downloadButton("downloadData","Download Table")
        )
      ),
      mainPanel(
        tabsetPanel(
          id="tabInput",
          tabPanel("Figures & Table",
                   plotOutput("lc_plot",height=400),
                   plotOutput("lc_hist",height=200),
                   DTOutput("table")),
          tabPanel("Mapping",
                   leafletOutput("map",height=600)),
          tabPanel("Time Series Mapping",
                   plotOutput("ts_map",height=700))
        )
      )
    )
  )
)

############################################################
# SERVER
############################################################

server <- function(input, output, session){
  
  smoothFunction <- function(x){
    stats::filter(as.numeric(x), rep(1/3,3), sides=2)
  }
  
  inputs <- reactive({
    years <- input$yearsInput[1]:input$yearsInput[2]
    units <- if(length(input$unitsInput)) input$unitsInput else NULL
    list(
      classes = input$classInput,
      units   = units,
      years   = years,
      metric  = input$metricInput
    )
  })
  
  ##########################################################
  # FILTERED DATA
  ##########################################################
  
  filtered_data <- reactive({
    req(length(input$classInput) > 0)
    p <- inputs()
    x <- lc |>
      filter(
        class_name %in% p$classes,
        year %in% p$years
      )
    if(!is.null(p$units))
      x <- x |> filter(unit_id %in% p$units)
    x
  })
  
  ##########################################################
  # TABLE DATA (GROUPED BY CLASS)
  ##########################################################
  
  datatable_data <- reactive({
    metric_col <- ifelse(inputs()$metric=="Percent Cover",
                         "pct","area_ha")
    filtered_data() |>
      group_by(year, class_name) |>
      summarise(
        value = sum(.data[[metric_col]], na.rm=TRUE),
        .groups="drop"
      ) |>
      arrange(class_name, year)
  })
  
  ##########################################################
  # FIGURES
  ##########################################################
  
  output$lc_plot <- renderPlot({
    dt <- datatable_data()
    if(isTRUE(input$smoothInput))
      dt <- dt |> group_by(class_name) |>
        mutate(value = smoothFunction(value)) |> ungroup()
    dt <- dt |> filter(!is.na(value))
    ggplot(dt,aes(year,value,color=class_name))+
      geom_line(linewidth=1.4)+
      theme_classic(base_size=16)+
      labs(
        x="Year",
        y=inputs()$metric,
        color="Class",
        title=paste(
          paste(inputs()$classes,collapse=", "),
          "Land Cover Change"
        )
      )
  })
  
  output$lc_hist <- renderPlot({
    dt <- datatable_data()
    ggplot(dt,
           aes(year,value,fill=class_name))+
      geom_col(position="dodge", color="black", width=0.8)+
      theme_classic(base_size=14)+
      labs(
        x="Year",
        y=inputs()$metric,
        fill="Class",
        title=paste(
          paste(inputs()$classes, collapse=", "),
          "Land Cover Change"
        )
      )
  })
  
  output$table <- renderDT(datatable_data())
  
  output$downloadData <- downloadHandler(
    filename=function(){
      paste0("BC_LandCover_",Sys.Date(),".csv")
    },
    content=function(file){
      write.csv(datatable_data(),file,row.names=FALSE)
    }
  )
  
  ##########################################################
  # MAPPING TAB (UPDATED POPUP WITH MU SIZE)
  ##########################################################
  
  output$map <- renderLeaflet({
    mapdata <- filtered_data() |>
      group_by(unit_id) |>
      summarise(
        avg_area_ha = mean(area_ha, na.rm=TRUE),
        avg_pct     = mean(pct, na.rm=TRUE),
        .groups="drop"
      )
    wm <- wmus |>
      st_transform(4326)
    # ---- NEW: calculate total MU area (ha) ----
    wm$total_mu_area_ha <- as.numeric(st_area(wm)) / 10000
    wm <- wm |>
      left_join(mapdata,
                by=c("WILDLIFE_M"="unit_id")) |>
      mutate(
        popup_text = paste0(
          "WMU: ",WILDLIFE_M,"<br>",
          "Total MU Area: ",
          format(round(total_mu_area_ha,1), big.mark=",")," ha<br>",
          "Average Area 1984-2022: ",
          round(avg_area_ha,1)," ha<br>",
          "Average Percentage 1984-2022: ",
          round(avg_pct,2),"%"
        )
      )
    pal <- colorNumeric("Greens",
                        wm$avg_area_ha,
                        na.color = NA)
    leaflet(wm) |>
      addProviderTiles("CartoDB.Voyager") |>
      addPolygons(
        weight=1,
        color="grey",
        fillColor=~pal(avg_area_ha),
        fillOpacity=0.6,
        popup=~popup_text
      ) |>
      addLegend("bottomright",
                pal=pal,
                values=~avg_area_ha)
  })
  
  ##########################################################
  # TIME SERIES MAPPING (NO NA PANEL)
  ##########################################################
  
  output$ts_map <- renderPlot({
    metric_col <- ifelse(inputs()$metric=="Percent Cover",
                         "pct","area_ha")
    agg <- filtered_data() |>
      group_by(unit_id, year) |>
      summarise(
        stat = mean(.data[[metric_col]], na.rm=TRUE),
        .groups="drop"
      ) |>
      filter(!is.na(year))
    wm_plot <- wmus |>
      left_join(agg,
                by=c("WILDLIFE_M"="unit_id")) |>
      filter(!is.na(year))
    ggplot(wm_plot) +
      geom_sf(aes(fill=stat), colour=NA) +
      facet_wrap(~year) +
      scale_fill_viridis_c(option="C") +
      theme_void() +
      labs(title="Time Series Land Cover Change")
  })
}

############################################################
# RUN APP
############################################################

shinyApp(ui, server,
         options=list(launch.browser=TRUE))