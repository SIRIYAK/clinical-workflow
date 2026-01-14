# ==============================================================================
# Protocol Deviation Tracking
# Script: protocol_deviation_tracking.R
# Purpose: Track, categorize, and report protocol deviations
# ==============================================================================

source("R/setup/00_install_packages.R")

library(dplyr)
library(glue)
library(writexl)

cat("\n========================================\n")
cat("Protocol Deviation Tracking\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Initialize Deviation Log
# ==============================================================================

initialize_deviation_log <- function() {
  
  deviation_log <- tibble(
    Deviation_ID = character(),
    USUBJID = character(),
    Site_Number = character(),
    Deviation_Date = as.Date(character()),
    Deviation_Category = character(),  # Inclusion/Exclusion, Informed Consent, Dosing, Visit Window, etc.
    Deviation_Type = character(),      # Major, Minor
    Deviation_Description = character(),
    Root_Cause = character(),
    Corrective_Action = character(),
    Preventive_Action = character(),
    Impact_on_Safety = character(),    # Yes, No
    Impact_on_Efficacy = character(),  # Yes, No
    Exclude_from_PP = character(),     # Yes, No (Per-Protocol population)
    Reported_By = character(),
    Reported_Date = as.Date(character()),
    Reviewed_By = character(),
    Review_Date = as.Date(character()),
    Status = character(),              # Open, Closed
    Comments = character()
  )
  
  dir.create("docs", showWarnings = FALSE, recursive = TRUE)
  writexl::write_xlsx(deviation_log, "docs/Protocol_Deviation_Log.xlsx")
  
  cat("✓ Protocol deviation log initialized: docs/Protocol_Deviation_Log.xlsx\n\n")
  
  return(deviation_log)
}

# ==============================================================================
# 2. Log Protocol Deviation
# ==============================================================================

log_protocol_deviation <- function(
  usubjid,
  site_number,
  deviation_date,
  category,
  type = "Minor",
  description,
  root_cause = "",
  impact_on_safety = "No",
  impact_on_efficacy = "No",
  exclude_from_pp = "No",
  reported_by = ""
) {
  
  log_file <- "docs/Protocol_Deviation_Log.xlsx"
  
  # Load existing log
  if (file.exists(log_file)) {
    deviation_log <- readxl::read_excel(log_file)
    next_id <- nrow(deviation_log) + 1
  } else {
    deviation_log <- initialize_deviation_log()
    next_id <- 1
  }
  
  # Create deviation ID
  deviation_id <- sprintf("DEV-%04d", next_id)
  
  # Create new entry
  new_deviation <- tibble(
    Deviation_ID = deviation_id,
    USUBJID = usubjid,
    Site_Number = site_number,
    Deviation_Date = as.Date(deviation_date),
    Deviation_Category = category,
    Deviation_Type = type,
    Deviation_Description = description,
    Root_Cause = root_cause,
    Corrective_Action = "",
    Preventive_Action = "",
    Impact_on_Safety = impact_on_safety,
    Impact_on_Efficacy = impact_on_efficacy,
    Exclude_from_PP = exclude_from_pp,
    Reported_By = reported_by,
    Reported_Date = Sys.Date(),
    Reviewed_By = "",
    Review_Date = as.Date(NA),
    Status = "Open",
    Comments = ""
  )
  
  # Add to log
  updated_log <- bind_rows(deviation_log, new_deviation)
  writexl::write_xlsx(updated_log, log_file)
  
  cat("✓ Protocol deviation logged\n")
  cat(glue("  Deviation ID: {deviation_id}\n"))
  cat(glue("  Subject: {usubjid}\n"))
  cat(glue("  Category: {category}\n"))
  cat(glue("  Type: {type}\n\n"))
  
  return(new_deviation)
}

# ==============================================================================
# 3. Generate Deviation Summary Report
# ==============================================================================

generate_deviation_summary <- function() {
  
  log_file <- "docs/Protocol_Deviation_Log.xlsx"
  
  if (!file.exists(log_file)) {
    cat("❌ No deviation log found.\n\n")
    return(NULL)
  }
  
  deviation_log <- readxl::read_excel(log_file)
  
  cat("\n========================================\n")
  cat("Protocol Deviation Summary\n")
  cat("========================================\n\n")
  
  # Overall summary
  overall_summary <- tibble(
    Metric = c(
      "Total Deviations",
      "Major Deviations",
      "Minor Deviations",
      "Open Deviations",
      "Closed Deviations",
      "Subjects with Deviations",
      "Sites with Deviations",
      "Deviations Impacting Safety",
      "Deviations Impacting Efficacy",
      "Subjects Excluded from PP"
    ),
    Value = c(
      nrow(deviation_log),
      sum(deviation_log$Deviation_Type == "Major", na.rm = TRUE),
      sum(deviation_log$Deviation_Type == "Minor", na.rm = TRUE),
      sum(deviation_log$Status == "Open", na.rm = TRUE),
      sum(deviation_log$Status == "Closed", na.rm = TRUE),
      n_distinct(deviation_log$USUBJID),
      n_distinct(deviation_log$Site_Number),
      sum(deviation_log$Impact_on_Safety == "Yes", na.rm = TRUE),
      sum(deviation_log$Impact_on_Efficacy == "Yes", na.rm = TRUE),
      sum(deviation_log$Exclude_from_PP == "Yes", na.rm = TRUE)
    )
  )
  
  # By category
  category_summary <- deviation_log %>%
    count(Deviation_Category, Deviation_Type, name = "N") %>%
    arrange(desc(N))
  
  # By site
  site_summary <- deviation_log %>%
    group_by(Site_Number) %>%
    summarise(
      Total_Deviations = n(),
      Major = sum(Deviation_Type == "Major", na.rm = TRUE),
      Minor = sum(Deviation_Type == "Minor", na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(Total_Deviations))
  
  # Save report
  report_list <- list(
    Overall_Summary = overall_summary,
    Category_Summary = category_summary,
    Site_Summary = site_summary,
    Deviation_Details = deviation_log
  )
  
  writexl::write_xlsx(report_list, "outputs/Protocol_Deviation_Summary.xlsx")
  
  cat("Overall Summary:\n")
  print(overall_summary)
  cat("\n")
  
  cat("✓ Deviation summary report saved: outputs/Protocol_Deviation_Summary.xlsx\n\n")
  
  return(report_list)
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Protocol Deviation Tracking Functions Loaded\n\n")

cat("Example usage:\n\n")

cat("# Initialize log:\n")
cat("initialize_deviation_log()\n\n")

cat("# Log deviation:\n")
cat('log_protocol_deviation(\n')
cat('  usubjid = "STUDY-001-USA-001-0001",\n')
cat('  site_number = "USA-001",\n')
cat('  deviation_date = "2024-06-15",\n')
cat('  category = "Visit Window",\n')
cat('  type = "Minor",\n')
cat('  description = "Week 12 visit occurred 3 days outside window",\n')
cat('  root_cause = "Subject scheduling conflict"\n')
cat(')\n\n')

cat("# Generate summary:\n")
cat("generate_deviation_summary()\n\n")
