# =============================================================================
# Interactive Study Dashboard Module
# Author: Siriyak
# Description: R Shiny app for real-time study visualization.
# =============================================================================

library(shiny)
library(dplyr)
library(ggplot2)

# Dummy Data Generator (for demonstration if real data missing)
generate_dummy_data <- function() {
    dates <- seq(as.Date("2024-01-01"), as.Date("2024-06-01"), by = "week")
    n <- length(dates)
    data.frame(
        Date = dates,
        Enrollment = cumsum(sample(1:5, n, replace = TRUE)),
        Queries_Open = sample(10:50, n, replace = TRUE),
        Queries_Closed = sample(5:40, n, replace = TRUE)
    )
}

ui <- fluidPage(
    theme = bslib::bs_theme(version = 4, bootswatch = "minty"),
    titlePanel("DQCC Study: Clinical Trial Dashboard"),
    sidebarLayout(
        sidebarPanel(
            selectInput("site_filter", "Select Site:", choices = c("All", "Site 101", "Site 102")),
            dateRangeInput("date_range", "Date Range:", start = "2024-01-01", end = Sys.Date()),
            hr(),
            downloadButton("report_dl", "Download Report")
        ),
        mainPanel(
            tabsetPanel(
                tabPanel(
                    "Overview",
                    fluidRow(
                        valueBoxOutput("box_enrolled", width = 4),
                        valueBoxOutput("box_queries", width = 4),
                        valueBoxOutput("box_aes", width = 4)
                    ),
                    br(),
                    h4("Enrollment Trend"),
                    plotOutput("enrollment_plot")
                ),
                tabPanel(
                    "Risk Monitoring",
                    h4("Site Risk Assessment"),
                    tableOutput("risk_table")
                ),
                tabPanel(
                    "Data Quality",
                    h4("Query Status Over Time"),
                    plotOutput("query_plot")
                )
            )
        )
    )
)

server <- function(input, output, session) {
    # Reactive Data Source
    dashboard_data <- reactive({
        # In integration, this would read from the 'all_results' outputs
        generate_dummy_data()
    })

    # Value Boxes (Using textOutput as simplified ValueBox for standard shiny)
    output$box_enrolled <- renderUI({
        wellPanel(h3(max(dashboard_data()$Enrollment)), p("Total Subjects Enrolled"))
    })
    output$box_queries <- renderUI({
        wellPanel(h3(sum(dashboard_data()$Queries_Open)), p("Open Queries"))
    })
    output$box_aes <- renderUI({
        wellPanel(h3("12"), p("Serious AEs (Mock)"))
    })

    # Plots
    output$enrollment_plot <- renderPlot({
        df <- dashboard_data()
        ggplot(df, aes(x = Date, y = Enrollment)) +
            geom_line(color = "blue", size = 1.5) +
            geom_area(fill = "lightblue", alpha = 0.5) +
            theme_minimal() +
            labs(title = "Cumulative Enrollment", y = "Subjects")
    })

    output$query_plot <- renderPlot({
        df <- dashboard_data()
        ggplot(df, aes(x = Date)) +
            geom_line(aes(y = Queries_Open, color = "Open"), size = 1.2) +
            geom_line(aes(y = Queries_Closed, color = "Closed"), size = 1.2) +
            scale_color_manual(values = c("Open" = "red", "Closed" = "green")) +
            theme_minimal() +
            labs(title = "Query Volume", y = "Count")
    })

    # Risk Table
    output$risk_table <- renderTable({
        data.frame(
            SiteID = c("101", "102", "103"),
            AE_Rate = c(0.4, 2.1, 0.8),
            Risk_Score = c("LOW", "HIGH", "MEDIUM"),
            Action = c("Routine", "Audit", "Review")
        )
    })
}

# Run the app
# shinyApp(ui = ui, server = server)
