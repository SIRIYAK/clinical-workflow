# ==============================================================================
# Enrollment Forecasting
# Script: enrollment_forecasting.R
# Purpose: Forecast enrollment and predict study completion dates
# ==============================================================================

source("R/setup/00_install_packages.R")

library(dplyr)
library(ggplot2)
library(glue)

cat("\n========================================\n")
cat("Enrollment Forecasting\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Calculate Enrollment Rate
# ==============================================================================

calculate_enrollment_rate <- function(subject_registry = NULL) {
  
  if (is.null(subject_registry)) {
    registry_file <- "docs/Subject_Registry.xlsx"
    if (!file.exists(registry_file)) {
      cat("❌ Subject registry not found.\n\n")
      return(NULL)
    }
    subject_registry <- readxl::read_excel(registry_file)
  }
  
  # Enrollment timeline
  enrollment_timeline <- subject_registry %>%
    count(Enrollment_Date, name = "N_Enrolled") %>%
    arrange(Enrollment_Date) %>%
    mutate(
      Cumulative_Enrollment = cumsum(N_Enrolled),
      Days_Since_Start = as.numeric(Enrollment_Date - min(Enrollment_Date))
    )
  
  # Calculate rate (subjects per day)
  total_days <- max(enrollment_timeline$Days_Since_Start)
  total_enrolled <- max(enrollment_timeline$Cumulative_Enrollment)
  enrollment_rate <- total_enrolled / total_days
  
  cat(glue("Current Enrollment Rate: {round(enrollment_rate, 2)} subjects/day\n"))
  cat(glue("Total Enrolled: {total_enrolled}\n"))
  cat(glue("Days Since Start: {total_days}\n\n"))
  
  return(list(
    timeline = enrollment_timeline,
    rate = enrollment_rate,
    total_enrolled = total_enrolled,
    total_days = total_days
  ))
}

# ==============================================================================
# 2. Forecast Enrollment
# ==============================================================================

forecast_enrollment <- function(target_enrollment, current_rate = NULL) {
  
  if (is.null(current_rate)) {
    enrollment_data <- calculate_enrollment_rate()
    current_rate <- enrollment_data$rate
    current_enrolled <- enrollment_data$total_enrolled
    start_date <- min(enrollment_data$timeline$Enrollment_Date)
  } else {
    current_enrolled <- 0
    start_date <- Sys.Date()
  }
  
  remaining_subjects <- target_enrollment - current_enrolled
  
  if (remaining_subjects <= 0) {
    cat("✓ Target enrollment already achieved!\n\n")
    return(NULL)
  }
  
  # Forecast completion
  days_to_completion <- remaining_subjects / current_rate
  predicted_completion_date <- Sys.Date() + days_to_completion
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          ENROLLMENT FORECAST                                   ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat(glue("Target Enrollment: {target_enrollment}\n"))
  cat(glue("Current Enrollment: {current_enrolled}\n"))
  cat(glue("Remaining: {remaining_subjects}\n\n"))
  
  cat(glue("Current Rate: {round(current_rate, 2)} subjects/day\n"))
  cat(glue("Days to Completion: {round(days_to_completion, 0)} days\n"))
  cat(glue("Predicted Completion: {predicted_completion_date}\n\n"))
  
  # Scenario analysis
  cat("Scenario Analysis:\n")
  cat(strrep("-", 60), "\n")
  
  scenarios <- tibble(
    Scenario = c("Optimistic (+50%)", "Current Rate", "Pessimistic (-50%)"),
    Rate = c(current_rate * 1.5, current_rate, current_rate * 0.5),
    Days = c(
      remaining_subjects / (current_rate * 1.5),
      days_to_completion,
      remaining_subjects / (current_rate * 0.5)
    ),
    Completion_Date = Sys.Date() + Days
  )
  
  print(scenarios)
  cat("\n")
  
  return(list(
    target = target_enrollment,
    current = current_enrolled,
    remaining = remaining_subjects,
    rate = current_rate,
    days_to_completion = days_to_completion,
    predicted_date = predicted_completion_date,
    scenarios = scenarios
  ))
}

# ==============================================================================
# 3. Generate Enrollment Forecast Plot
# ==============================================================================

generate_enrollment_forecast_plot <- function(target_enrollment, forecast_data = NULL) {
  
  if (is.null(forecast_data)) {
    forecast_data <- forecast_enrollment(target_enrollment)
  }
  
  enrollment_data <- calculate_enrollment_rate()
  
  # Historical data
  historical <- enrollment_data$timeline %>%
    select(Date = Enrollment_Date, Cumulative = Cumulative_Enrollment) %>%
    mutate(Type = "Actual")
  
  # Forecast data
  forecast_dates <- seq(Sys.Date(), forecast_data$predicted_date, by = "day")
  forecast_cumulative <- seq(
    forecast_data$current,
    target_enrollment,
    length.out = length(forecast_dates)
  )
  
  forecast <- tibble(
    Date = forecast_dates,
    Cumulative = forecast_cumulative,
    Type = "Forecast"
  )
  
  # Combine
  plot_data <- bind_rows(historical, forecast)
  
  # Create plot
  p <- ggplot(plot_data, aes(x = Date, y = Cumulative, color = Type, linetype = Type)) +
    geom_line(size = 1.2) +
    geom_hline(yintercept = target_enrollment, linetype = "dashed", color = "red") +
    annotate("text", x = max(plot_data$Date), y = target_enrollment + 5,
             label = glue("Target: {target_enrollment}"), hjust = 1) +
    labs(
      title = "Enrollment Forecast",
      subtitle = glue("Predicted Completion: {forecast_data$predicted_date}"),
      x = "Date",
      y = "Cumulative Enrollment",
      color = "",
      linetype = ""
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 16, face = "bold"),
      legend.position = "bottom"
    )
  
  # Save plot
  ggsave("outputs/Enrollment_Forecast.png", p, width = 10, height = 6, dpi = 300)
  
  cat("✓ Enrollment forecast plot saved: outputs/Enrollment_Forecast.png\n\n")
  
  return(p)
}

# ==============================================================================
# 4. Site-Level Forecasting
# ==============================================================================

forecast_by_site <- function(target_by_site) {
  
  registry_file <- "docs/Subject_Registry.xlsx"
  if (!file.exists(registry_file)) {
    cat("❌ Subject registry not found.\n\n")
    return(NULL)
  }
  
  subject_registry <- readxl::read_excel(registry_file)
  
  # Calculate site-level rates
  site_forecasts <- subject_registry %>%
    group_by(Site_Number) %>%
    summarise(
      Current_Enrollment = n(),
      First_Enrollment = min(Enrollment_Date),
      Last_Enrollment = max(Enrollment_Date),
      Days_Active = as.numeric(Last_Enrollment - First_Enrollment) + 1,
      .groups = "drop"
    ) %>%
    mutate(
      Enrollment_Rate = Current_Enrollment / Days_Active
    )
  
  # Add targets
  if (!is.null(target_by_site)) {
    site_forecasts <- site_forecasts %>%
      left_join(target_by_site, by = "Site_Number") %>%
      mutate(
        Remaining = Target_Enrollment - Current_Enrollment,
        Days_to_Target = Remaining / Enrollment_Rate,
        Predicted_Completion = Sys.Date() + Days_to_Target
      )
  }
  
  cat("Site-Level Enrollment Forecast:\n")
  print(site_forecasts)
  cat("\n")
  
  writexl::write_xlsx(site_forecasts, "outputs/Site_Enrollment_Forecast.xlsx")
  cat("✓ Site forecast saved: outputs/Site_Enrollment_Forecast.xlsx\n\n")
  
  return(site_forecasts)
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Enrollment Forecasting Functions Loaded\n\n")

cat("Example usage:\n\n")

cat("# Calculate current rate:\n")
cat("calculate_enrollment_rate()\n\n")

cat("# Forecast enrollment:\n")
cat("forecast_enrollment(target_enrollment = 300)\n\n")

cat("# Generate forecast plot:\n")
cat("generate_enrollment_forecast_plot(target_enrollment = 300)\n\n")

cat("# Site-level forecast:\n")
cat("forecast_by_site(target_by_site = tibble(Site_Number = c('USA-001', 'GBR-001'), Target_Enrollment = c(150, 150)))\n\n")
