# ==============================================================================
# Data Quality Dashboard (Shiny App)
# Script: data_quality_dashboard.R
# Purpose: Interactive dashboard for real-time data quality monitoring
# ==============================================================================

# Install shiny if not already installed
if (!require("shiny")) install.packages("shiny")
if (!require("shinydashboard")) install.packages("shinydashboard")
if (!require("DT")) install.packages("DT")
if (!require("plotly")) install.packages("plotly")

library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)

# ==============================================================================
# UI
# ==============================================================================

ui <- dashboardPage(
  dashboardHeader(title = "Data Quality Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Enrollment", tabName = "enrollment", icon = icon("users")),
      menuItem("Data Quality", tabName = "quality", icon = icon("check-circle")),
      menuItem("Site Performance", tabName = "sites", icon = icon("hospital")),
      menuItem("Protocol Deviations", tabName = "deviations", icon = icon("exclamation-triangle"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
        fluidRow(
          valueBoxOutput("total_subjects"),
          valueBoxOutput("active_sites"),
          valueBoxOutput("completion_rate")
        ),
        fluidRow(
          box(
            title = "Enrollment Over Time",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("enrollment_plot")
          )
        )
      ),
      
      # Enrollment Tab
      tabItem(tabName = "enrollment",
        fluidRow(
          box(
            title = "Enrollment by Site",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("enrollment_by_site")
          ),
          box(
            title = "Enrollment Forecast",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("enrollment_forecast")
          )
        ),
        fluidRow(
          box(
            title = "Site Enrollment Details",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("site_enrollment_table")
          )
        )
      ),
      
      # Data Quality Tab
      tabItem(tabName = "quality",
        fluidRow(
          valueBoxOutput("missing_data_rate"),
          valueBoxOutput("query_rate"),
          valueBoxOutput("data_completeness")
        ),
        fluidRow(
          box(
            title = "Missing Data by Domain",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("missing_data_plot")
          ),
          box(
            title = "Query Status",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("query_status_plot")
          )
        )
      ),
      
      # Site Performance Tab
      tabItem(tabName = "sites",
        fluidRow(
          box(
            title = "Site Performance Metrics",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("site_performance_table")
          )
        ),
        fluidRow(
          box(
            title = "Site Risk Score",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("site_risk_plot")
          )
        )
      ),
      
      # Protocol Deviations Tab
      tabItem(tabName = "deviations",
        fluidRow(
          valueBoxOutput("total_deviations"),
          valueBoxOutput("major_deviations"),
          valueBoxOutput("open_deviations")
        ),
        fluidRow(
          box(
            title = "Deviations by Category",
            status = "danger",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("deviation_category_plot")
          ),
          box(
            title = "Deviations by Site",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("deviation_site_plot")
          )
        )
      )
    )
  )
)

# ==============================================================================
# Server
# ==============================================================================

server <- function(input, output, session) {
  
  # Load data (reactive)
  subject_data <- reactive({
    # Load subject registry
    if (file.exists("docs/Subject_Registry.xlsx")) {
      readxl::read_excel("docs/Subject_Registry.xlsx")
    } else {
      tibble(USUBJID = character(), Site_Number = character(), 
             Enrollment_Date = as.Date(character()), Subject_Status = character())
    }
  })
  
  deviation_data <- reactive({
    # Load deviation log
    if (file.exists("docs/Protocol_Deviation_Log.xlsx")) {
      readxl::read_excel("docs/Protocol_Deviation_Log.xlsx")
    } else {
      tibble(Deviation_ID = character(), Deviation_Type = character(), 
             Site_Number = character(), Status = character())
    }
  })
  
  # Overview Tab - Value Boxes
  output$total_subjects <- renderValueBox({
    valueBox(
      nrow(subject_data()),
      "Total Subjects",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$active_sites <- renderValueBox({
    valueBox(
      n_distinct(subject_data()$Site_Number),
      "Active Sites",
      icon = icon("hospital"),
      color = "green"
    )
  })
  
  output$completion_rate <- renderValueBox({
    completed <- sum(subject_data()$Subject_Status == "Completed", na.rm = TRUE)
    total <- nrow(subject_data())
    rate <- if (total > 0) round(completed / total * 100, 1) else 0
    
    valueBox(
      paste0(rate, "%"),
      "Completion Rate",
      icon = icon("check-circle"),
      color = "yellow"
    )
  })
  
  # Enrollment Plot
  output$enrollment_plot <- renderPlotly({
    enrollment_timeline <- subject_data() %>%
      count(Enrollment_Date, name = "N") %>%
      arrange(Enrollment_Date) %>%
      mutate(Cumulative = cumsum(N))
    
    p <- ggplot(enrollment_timeline, aes(x = Enrollment_Date, y = Cumulative)) +
      geom_line(color = "steelblue", size = 1.2) +
      geom_point(color = "steelblue", size = 2) +
      labs(title = "", x = "Date", y = "Cumulative Enrollment") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Enrollment by Site
  output$enrollment_by_site <- renderPlotly({
    site_enrollment <- subject_data() %>%
      count(Site_Number, name = "N") %>%
      arrange(desc(N))
    
    p <- ggplot(site_enrollment, aes(x = reorder(Site_Number, N), y = N)) +
      geom_col(fill = "steelblue") +
      coord_flip() +
      labs(title = "", x = "Site", y = "Subjects Enrolled") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Site Enrollment Table
  output$site_enrollment_table <- renderDT({
    subject_data() %>%
      group_by(Site_Number) %>%
      summarise(
        Total_Enrolled = n(),
        Screening = sum(Subject_Status == "Screening", na.rm = TRUE),
        Randomized = sum(Subject_Status == "Randomized", na.rm = TRUE),
        Completed = sum(Subject_Status == "Completed", na.rm = TRUE),
        Discontinued = sum(Subject_Status == "Discontinued", na.rm = TRUE),
        .groups = "drop"
      ) %>%
      datatable(options = list(pageLength = 10))
  })
  
  # Deviations Value Boxes
  output$total_deviations <- renderValueBox({
    valueBox(
      nrow(deviation_data()),
      "Total Deviations",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$major_deviations <- renderValueBox({
    major <- sum(deviation_data()$Deviation_Type == "Major", na.rm = TRUE)
    valueBox(
      major,
      "Major Deviations",
      icon = icon("exclamation-circle"),
      color = "red"
    )
  })
  
  output$open_deviations <- renderValueBox({
    open <- sum(deviation_data()$Status == "Open", na.rm = TRUE)
    valueBox(
      open,
      "Open Deviations",
      icon = icon("folder-open"),
      color = "orange"
    )
  })
  
  # Deviations by Category
  output$deviation_category_plot <- renderPlotly({
    if (nrow(deviation_data()) > 0) {
      category_summary <- deviation_data() %>%
        count(Deviation_Category, name = "N") %>%
        arrange(desc(N))
      
      p <- ggplot(category_summary, aes(x = reorder(Deviation_Category, N), y = N)) +
        geom_col(fill = "coral") +
        coord_flip() +
        labs(title = "", x = "Category", y = "Count") +
        theme_minimal()
      
      ggplotly(p)
    } else {
      plotly_empty()
    }
  })
}

# ==============================================================================
# Run App
# ==============================================================================

cat("\n========================================\n")
cat("Data Quality Dashboard (Shiny App)\n")
cat("========================================\n\n")

cat("To launch the dashboard, run:\n")
cat("  shiny::runApp('R/dashboards/data_quality_dashboard.R')\n\n")

cat("Dashboard features:\n")
cat("  • Real-time enrollment monitoring\n")
cat("  • Site performance tracking\n")
cat("  • Data quality metrics\n")
cat("  • Protocol deviation tracking\n")
cat("  • Interactive visualizations\n\n")

# Uncomment to run the app
# shinyApp(ui, server)
