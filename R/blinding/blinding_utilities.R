# ==============================================================================
# Blinding Utilities
# Script: blinding_utilities.R
# Purpose: Core functions for blinding and unblinding procedures
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")

library(dplyr)
library(glue)

cat("\n========================================\n")
cat("Blinding Utilities\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Initialize Blinding Log
# ==============================================================================

initialize_blinding_log <- function() {
  
  blinding_log <- tibble(
    Log_ID = character(),
    Date = as.Date(character()),
    Time = character(),
    Event_Type = character(),  # "Randomization", "Emergency Unblinding", "Planned Unblinding"
    Subject_ID = character(),
    Requested_By = character(),
    Reason = character(),
    Approved_By = character(),
    Treatment_Revealed = character(),
    Documentation = character(),
    Comments = character()
  )
  
  dir.create("docs", showWarnings = FALSE, recursive = TRUE)
  writexl::write_xlsx(blinding_log, "docs/Blinding_Unblinding_Log.xlsx")
  
  cat("✓ Blinding/Unblinding log initialized: docs/Blinding_Unblinding_Log.xlsx\n\n")
  
  return(blinding_log)
}

# ==============================================================================
# 2. Mask Treatment Assignments
# ==============================================================================

mask_treatment_assignments <- function(data, blinded = TRUE, treatment_var = "TRT01P") {
  
  if (!blinded) {
    cat("⚠ WARNING: Running UNBLINDED analysis\n")
    cat("  Treatment assignments will NOT be masked\n\n")
    return(data)
  }
  
  cat("Masking treatment assignments for blinded analysis...\n")
  
  # Store original treatment
  data_masked <- data %>%
    mutate(
      !!paste0(treatment_var, "_ORIGINAL") := !!sym(treatment_var)
    )
  
  # Get unique treatments
  unique_treatments <- unique(data[[treatment_var]])
  
  # Create mapping
  treatment_mapping <- tibble(
    Original = unique_treatments,
    Masked = paste0("Treatment ", seq_along(unique_treatments))
  )
  
  # Apply masking
  data_masked <- data_masked %>%
    mutate(
      !!treatment_var := case_when(
        !!sym(treatment_var) %in% treatment_mapping$Original ~ 
          treatment_mapping$Masked[match(!!sym(treatment_var), treatment_mapping$Original)],
        TRUE ~ !!sym(treatment_var)
      )
    )
  
  cat("✓ Treatment assignments masked:\n")
  print(treatment_mapping)
  cat("\n")
  cat(glue("  Original labels stored in {treatment_var}_ORIGINAL\n\n"))
  
  return(data_masked)
}

# ==============================================================================
# 3. Unmask Treatment Assignments
# ==============================================================================

unmask_treatment_assignments <- function(data, treatment_var = "TRT01P") {
  
  original_var <- paste0(treatment_var, "_ORIGINAL")
  
  if (!original_var %in% names(data)) {
    cat("⚠ WARNING: No masked treatment found. Data may already be unmasked.\n\n")
    return(data)
  }
  
  cat("Unmasking treatment assignments...\n")
  
  data_unmasked <- data %>%
    mutate(
      !!treatment_var := !!sym(original_var)
    ) %>%
    select(-!!sym(original_var))
  
  cat("✓ Treatment assignments unmasked\n\n")
  
  return(data_unmasked)
}

# ==============================================================================
# 4. Log Blinding Event
# ==============================================================================

log_blinding_event <- function(event_type, subject_id = "All subjects", 
                               requested_by, reason, approved_by = "",
                               treatment_revealed = "", documentation = "",
                               comments = "") {
  
  log_file <- "docs/Blinding_Unblinding_Log.xlsx"
  
  # Create new entry
  new_entry <- tibble(
    Log_ID = paste0(toupper(substr(event_type, 1, 3)), "-", format(Sys.time(), "%Y%m%d-%H%M%S")),
    Date = Sys.Date(),
    Time = format(Sys.time(), "%H:%M:%S"),
    Event_Type = event_type,
    Subject_ID = subject_id,
    Requested_By = requested_by,
    Reason = reason,
    Approved_By = approved_by,
    Treatment_Revealed = treatment_revealed,
    Documentation = documentation,
    Comments = comments
  )
  
  # Append to existing log
  if (file.exists(log_file)) {
    existing_log <- readxl::read_excel(log_file)
    updated_log <- bind_rows(existing_log, new_entry)
  } else {
    updated_log <- new_entry
  }
  
  writexl::write_xlsx(updated_log, log_file)
  
  cat(glue("✓ Event logged: {new_entry$Log_ID}\n"))
  cat(glue("  Type: {event_type}\n"))
  cat(glue("  Subject: {subject_id}\n"))
  cat(glue("  Date/Time: {new_entry$Date} {new_entry$Time}\n\n"))
  
  return(new_entry)
}

# ==============================================================================
# 5. Check Blinding Status
# ==============================================================================

check_blinding_status <- function(data, treatment_var = "TRT01P") {
  
  original_var <- paste0(treatment_var, "_ORIGINAL")
  
  if (original_var %in% names(data)) {
    cat("✓ Data is BLINDED\n")
    cat(glue("  Masked variable: {treatment_var}\n"))
    cat(glue("  Original variable: {original_var}\n\n"))
    
    # Show masked treatments
    cat("Masked Treatment Groups:\n")
    print(data %>% count(!!sym(treatment_var)))
    
    return("BLINDED")
  } else {
    cat("⚠ Data is UNBLINDED\n")
    cat(glue("  Treatment variable: {treatment_var}\n\n"))
    
    # Show actual treatments
    cat("Treatment Groups:\n")
    print(data %>% count(!!sym(treatment_var)))
    
    return("UNBLINDED")
  }
}

# ==============================================================================
# 6. Generate Blinding Integrity Report
# ==============================================================================

generate_blinding_integrity_report <- function(data) {
  
  cat("\n========================================\n")
  cat("Blinding Integrity Assessment\n")
  cat("========================================\n\n")
  
  log_file <- "docs/Blinding_Unblinding_Log.xlsx"
  
  if (!file.exists(log_file)) {
    cat("No unblinding events recorded\n")
    cat("Blinding Integrity: EXCELLENT (0% unblinded)\n\n")
    
    integrity_report <- tibble(
      Metric = c("Total Subjects", "Emergency Unblinding Events", "Percentage Unblinded", "Status"),
      Value = c(nrow(data), 0, "0%", "Excellent")
    )
    
  } else {
    
    unblinding_log <- readxl::read_excel(log_file)
    
    emergency_events <- unblinding_log %>%
      filter(Event_Type == "Emergency Unblinding")
    
    n_emergency <- nrow(emergency_events)
    pct_unblinded <- round(n_emergency / nrow(data) * 100, 2)
    
    status <- case_when(
      pct_unblinded == 0 ~ "Excellent (0%)",
      pct_unblinded < 5 ~ "Acceptable (<5%)",
      pct_unblinded >= 5 ~ "Concerning (≥5%)"
    )
    
    cat(glue("Total Subjects: {nrow(data)}\n"))
    cat(glue("Emergency Unblinding Events: {n_emergency}\n"))
    cat(glue("Percentage Unblinded: {pct_unblinded}%\n"))
    cat(glue("Status: {status}\n\n"))
    
    if (n_emergency > 0) {
      cat("Emergency Unblinding Events:\n")
      print(emergency_events %>% select(Date, Subject_ID, Reason, Approved_By))
      cat("\n")
    }
    
    integrity_report <- tibble(
      Metric = c("Total Subjects", "Emergency Unblinding Events", "Percentage Unblinded", "Status"),
      Value = c(as.character(nrow(data)), as.character(n_emergency), paste0(pct_unblinded, "%"), status)
    )
  }
  
  # Save report
  writexl::write_xlsx(integrity_report, "outputs/Blinding_Integrity_Report.xlsx")
  cat("✓ Blinding integrity report saved: outputs/Blinding_Integrity_Report.xlsx\n\n")
  
  return(integrity_report)
}

# ==============================================================================
# 7. View Blinding Log
# ==============================================================================

view_blinding_log <- function(event_type = NULL) {
  
  log_file <- "docs/Blinding_Unblinding_Log.xlsx"
  
  if (!file.exists(log_file)) {
    cat("No blinding log found. Run initialize_blinding_log() first.\n\n")
    return(NULL)
  }
  
  log_data <- readxl::read_excel(log_file)
  
  if (!is.null(event_type)) {
    log_data <- log_data %>% filter(Event_Type == event_type)
  }
  
  if (nrow(log_data) == 0) {
    cat("No events found in blinding log.\n\n")
    return(NULL)
  }
  
  cat("\n========================================\n")
  cat("Blinding/Unblinding Log\n")
  cat("========================================\n\n")
  
  print(log_data)
  cat("\n")
  
  return(log_data)
}

cat("✓ Blinding utilities loaded\n\n")

cat("Available functions:\n")
cat("  • initialize_blinding_log()\n")
cat("  • mask_treatment_assignments(data, blinded = TRUE)\n")
cat("  • unmask_treatment_assignments(data)\n")
cat("  • log_blinding_event(...)\n")
cat("  • check_blinding_status(data)\n")
cat("  • generate_blinding_integrity_report(data)\n")
cat("  • view_blinding_log(event_type = NULL)\n\n")
