# ==============================================================================
# Subject ID Generation Utilities
# Script: subject_id_generation.R
# Purpose: Generate USUBJID, SUBJID, and manage subject enrollment
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/site_management/site_management.R")

library(dplyr)
library(glue)

cat("\n========================================\n")
cat("Subject ID Generation Utilities\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Initialize Subject Registry
# ==============================================================================

initialize_subject_registry <- function() {
  
  subject_registry <- tibble(
    USUBJID = character(),
    SUBJID = character(),
    Site_Number = character(),
    Screening_Number = character(),
    Randomization_Number = character(),
    Enrollment_Date = as.Date(character()),
    Randomization_Date = as.Date(character()),
    Treatment_Assignment = character(),
    Subject_Status = character(),  # Screening, Enrolled, Randomized, Completed, Discontinued
    Discontinuation_Reason = character(),
    Comments = character()
  )
  
  dir.create("docs", showWarnings = FALSE, recursive = TRUE)
  writexl::write_xlsx(subject_registry, "docs/Subject_Registry.xlsx")
  
  cat("✓ Subject registry initialized: docs/Subject_Registry.xlsx\n\n")
  
  return(subject_registry)
}

# ==============================================================================
# 2. Generate SUBJID (Site-Specific Subject ID)
# ==============================================================================

generate_subjid <- function(site_number, sequential_number = NULL, 
                           format = "SSSS-NNNN") {
  
  # If sequential number not provided, get next available
  if (is.null(sequential_number)) {
    registry_file <- "docs/Subject_Registry.xlsx"
    
    if (file.exists(registry_file)) {
      subject_registry <- readxl::read_excel(registry_file)
      
      # Get subjects at this site
      site_subjects <- subject_registry %>%
        filter(Site_Number == site_number)
      
      if (nrow(site_subjects) > 0) {
        # Extract sequential numbers
        existing_numbers <- as.numeric(gsub(".*-(\\d+)$", "\\1", site_subjects$SUBJID))
        sequential_number <- max(existing_numbers, na.rm = TRUE) + 1
      } else {
        sequential_number <- 1
      }
    } else {
      sequential_number <- 1
    }
  }
  
  # Format options:
  # "SSSS-NNNN" = Site number - Sequential number (4 digits)
  # "SSSSNNNN" = Site number + Sequential number (no separator)
  # "NNNN" = Sequential number only (4 digits)
  
  subjid <- switch(format,
    "SSSS-NNNN" = glue("{site_number}-{sprintf('%04d', sequential_number)}"),
    "SSSSNNNN" = glue("{site_number}{sprintf('%04d', sequential_number)}"),
    "NNNN" = sprintf("%04d", sequential_number),
    glue("{site_number}-{sprintf('%04d', sequential_number)}")  # Default
  )
  
  return(as.character(subjid))
}

# ==============================================================================
# 3. Generate USUBJID (Unique Subject ID)
# ==============================================================================

generate_usubjid <- function(study_id, subjid, format = "STUDY-SUBJID") {
  
  # Format options:
  # "STUDY-SUBJID" = Study ID - Subject ID
  # "STUDYSUBJID" = Study ID + Subject ID (no separator)
  # "SUBJID" = Subject ID only
  
  usubjid <- switch(format,
    "STUDY-SUBJID" = glue("{study_id}-{subjid}"),
    "STUDYSUBJID" = glue("{study_id}{subjid}"),
    "SUBJID" = subjid,
    glue("{study_id}-{subjid}")  # Default
  )
  
  return(as.character(usubjid))
}

# ==============================================================================
# 4. Generate Screening Number
# ==============================================================================

generate_screening_number <- function(site_number, sequential_number = NULL,
                                     format = "SCR-SSSS-NNNN") {
  
  # If sequential number not provided, get next available
  if (is.null(sequential_number)) {
    registry_file <- "docs/Subject_Registry.xlsx"
    
    if (file.exists(registry_file)) {
      subject_registry <- readxl::read_excel(registry_file)
      
      # Get screening subjects at this site
      site_screens <- subject_registry %>%
        filter(Site_Number == site_number, !is.na(Screening_Number))
      
      if (nrow(site_screens) > 0) {
        existing_numbers <- as.numeric(gsub(".*-(\\d+)$", "\\1", site_screens$Screening_Number))
        sequential_number <- max(existing_numbers, na.rm = TRUE) + 1
      } else {
        sequential_number <- 1
      }
    } else {
      sequential_number <- 1
    }
  }
  
  # Format options:
  # "SCR-SSSS-NNNN" = SCR prefix - Site number - Sequential
  # "SCRSSSSNNNN" = All concatenated
  # "SSSS-SCR-NNNN" = Site - SCR - Sequential
  
  screening_number <- switch(format,
    "SCR-SSSS-NNNN" = glue("SCR-{site_number}-{sprintf('%04d', sequential_number)}"),
    "SCRSSSSNNNN" = glue("SCR{site_number}{sprintf('%04d', sequential_number)}"),
    "SSSS-SCR-NNNN" = glue("{site_number}-SCR-{sprintf('%04d', sequential_number)}"),
    glue("SCR-{site_number}-{sprintf('%04d', sequential_number)}")  # Default
  )
  
  return(as.character(screening_number))
}

# ==============================================================================
# 5. Enroll Subject
# ==============================================================================

enroll_subject <- function(site_number, study_id = "STUDY-001",
                          enrollment_date = Sys.Date(),
                          subjid_format = "SSSS-NNNN",
                          usubjid_format = "STUDY-SUBJID",
                          screening_format = "SCR-SSSS-NNNN") {
  
  registry_file <- "docs/Subject_Registry.xlsx"
  
  # Load or create registry
  if (file.exists(registry_file)) {
    subject_registry <- readxl::read_excel(registry_file)
  } else {
    subject_registry <- initialize_subject_registry()
  }
  
  # Generate IDs
  screening_number <- generate_screening_number(site_number, format = screening_format)
  subjid <- generate_subjid(site_number, format = subjid_format)
  usubjid <- generate_usubjid(study_id, subjid, format = usubjid_format)
  
  # Create new subject entry
  new_subject <- tibble(
    USUBJID = usubjid,
    SUBJID = subjid,
    Site_Number = site_number,
    Screening_Number = screening_number,
    Randomization_Number = NA_character_,
    Enrollment_Date = as.Date(enrollment_date),
    Randomization_Date = as.Date(NA),
    Treatment_Assignment = NA_character_,
    Subject_Status = "Screening",
    Discontinuation_Reason = NA_character_,
    Comments = ""
  )
  
  # Add to registry
  updated_registry <- bind_rows(subject_registry, new_subject)
  
  # Save
  writexl::write_xlsx(updated_registry, registry_file)
  
  # Update site enrollment
  site_registry_file <- "docs/Site_Registry.xlsx"
  if (file.exists(site_registry_file)) {
    site_registry <- readxl::read_excel(site_registry_file)
    current_enrollment <- site_registry %>%
      filter(Site_Number == site_number) %>%
      pull(Actual_Enrollment)
    
    if (length(current_enrollment) > 0) {
      update_site_enrollment(site_number, current_enrollment[1] + 1)
    }
  }
  
  cat("✓ Subject enrolled\n")
  cat(glue("  USUBJID: {usubjid}\n"))
  cat(glue("  SUBJID: {subjid}\n"))
  cat(glue("  Screening Number: {screening_number}\n"))
  cat(glue("  Site: {site_number}\n"))
  cat(glue("  Enrollment Date: {enrollment_date}\n\n"))
  
  return(new_subject)
}

# ==============================================================================
# 6. Randomize Subject
# ==============================================================================

randomize_subject <- function(usubjid, treatment_assignment, 
                             randomization_number = NULL,
                             randomization_date = Sys.Date()) {
  
  registry_file <- "docs/Subject_Registry.xlsx"
  
  if (!file.exists(registry_file)) {
    cat("❌ Subject registry not found.\n\n")
    return(NULL)
  }
  
  subject_registry <- readxl::read_excel(registry_file)
  
  # Generate randomization number if not provided
  if (is.null(randomization_number)) {
    randomized_subjects <- subject_registry %>%
      filter(!is.na(Randomization_Number))
    
    if (nrow(randomized_subjects) > 0) {
      existing_numbers <- as.numeric(gsub(".*-(\\d+)$", "\\1", randomized_subjects$Randomization_Number))
      next_number <- max(existing_numbers, na.rm = TRUE) + 1
    } else {
      next_number <- 1
    }
    
    randomization_number <- sprintf("RAND-%04d", next_number)
  }
  
  # Update subject
  subject_registry <- subject_registry %>%
    mutate(
      Randomization_Number = if_else(USUBJID == usubjid, randomization_number, Randomization_Number),
      Randomization_Date = if_else(USUBJID == usubjid, as.Date(randomization_date), Randomization_Date),
      Treatment_Assignment = if_else(USUBJID == usubjid, treatment_assignment, Treatment_Assignment),
      Subject_Status = if_else(USUBJID == usubjid, "Randomized", Subject_Status)
    )
  
  writexl::write_xlsx(subject_registry, registry_file)
  
  cat(glue("✓ Subject {usubjid} randomized\n"))
  cat(glue("  Randomization Number: {randomization_number}\n"))
  cat(glue("  Treatment: {treatment_assignment}\n"))
  cat(glue("  Date: {randomization_date}\n\n"))
  
  return(subject_registry %>% filter(USUBJID == usubjid))
}

# ==============================================================================
# 7. Update Subject Status
# ==============================================================================

update_subject_status <- function(usubjid, status, 
                                 discontinuation_reason = NA,
                                 comments = "") {
  
  registry_file <- "docs/Subject_Registry.xlsx"
  
  if (!file.exists(registry_file)) {
    cat("❌ Subject registry not found.\n\n")
    return(NULL)
  }
  
  subject_registry <- readxl::read_excel(registry_file)
  
  # Update status
  subject_registry <- subject_registry %>%
    mutate(
      Subject_Status = if_else(USUBJID == usubjid, status, Subject_Status),
      Discontinuation_Reason = if_else(USUBJID == usubjid & !is.na(discontinuation_reason), 
                                      discontinuation_reason, 
                                      Discontinuation_Reason),
      Comments = if_else(USUBJID == usubjid & comments != "", 
                        paste(Comments, comments, sep = "; "), 
                        Comments)
    )
  
  writexl::write_xlsx(subject_registry, registry_file)
  
  cat(glue("✓ Subject {usubjid} status updated to: {status}\n\n"))
  
  return(subject_registry %>% filter(USUBJID == usubjid))
}

# ==============================================================================
# 8. View Subject Registry
# ==============================================================================

view_subject_registry <- function(site_number = NULL, status = NULL) {
  
  registry_file <- "docs/Subject_Registry.xlsx"
  
  if (!file.exists(registry_file)) {
    cat("❌ Subject registry not found.\n\n")
    return(NULL)
  }
  
  subject_registry <- readxl::read_excel(registry_file)
  
  # Filter by site
  if (!is.null(site_number)) {
    subject_registry <- subject_registry %>% filter(Site_Number == site_number)
  }
  
  # Filter by status
  if (!is.null(status)) {
    subject_registry <- subject_registry %>% filter(Subject_Status == status)
  }
  
  cat("\n========================================\n")
  cat("Subject Registry\n")
  cat("========================================\n\n")
  
  if (nrow(subject_registry) == 0) {
    cat("No subjects found.\n\n")
    return(NULL)
  }
  
  print(subject_registry %>%
    select(USUBJID, SUBJID, Site_Number, Screening_Number, 
           Subject_Status, Enrollment_Date, Treatment_Assignment))
  
  cat("\n")
  cat(glue("Total Subjects: {nrow(subject_registry)}\n"))
  cat(glue("Screening: {sum(subject_registry$Subject_Status == 'Screening', na.rm = TRUE)}\n"))
  cat(glue("Randomized: {sum(subject_registry$Subject_Status == 'Randomized', na.rm = TRUE)}\n"))
  cat(glue("Completed: {sum(subject_registry$Subject_Status == 'Completed', na.rm = TRUE)}\n"))
  cat(glue("Discontinued: {sum(subject_registry$Subject_Status == 'Discontinued', na.rm = TRUE)}\n\n"))
  
  return(subject_registry)
}

# ==============================================================================
# 9. Generate Enrollment Report
# ==============================================================================

generate_enrollment_report <- function() {
  
  registry_file <- "docs/Subject_Registry.xlsx"
  
  if (!file.exists(registry_file)) {
    cat("❌ Subject registry not found.\n\n")
    return(NULL)
  }
  
  subject_registry <- readxl::read_excel(registry_file)
  
  # Enrollment by site
  site_enrollment <- subject_registry %>%
    group_by(Site_Number) %>%
    summarise(
      Total_Enrolled = n(),
      Screening = sum(Subject_Status == "Screening", na.rm = TRUE),
      Randomized = sum(Subject_Status == "Randomized", na.rm = TRUE),
      Completed = sum(Subject_Status == "Completed", na.rm = TRUE),
      Discontinued = sum(Subject_Status == "Discontinued", na.rm = TRUE),
      .groups = "drop"
    )
  
  # Enrollment by status
  status_summary <- subject_registry %>%
    count(Subject_Status, name = "N_Subjects")
  
  # Enrollment over time
  enrollment_timeline <- subject_registry %>%
    count(Enrollment_Date, name = "N_Enrolled") %>%
    arrange(Enrollment_Date) %>%
    mutate(Cumulative_Enrollment = cumsum(N_Enrolled))
  
  # Overall summary
  overall_summary <- tibble(
    Metric = c(
      "Total Subjects Enrolled",
      "Subjects in Screening",
      "Subjects Randomized",
      "Subjects Completed",
      "Subjects Discontinued",
      "Randomization Rate (%)"
    ),
    Value = c(
      nrow(subject_registry),
      sum(subject_registry$Subject_Status == "Screening", na.rm = TRUE),
      sum(subject_registry$Subject_Status == "Randomized", na.rm = TRUE),
      sum(subject_registry$Subject_Status == "Completed", na.rm = TRUE),
      sum(subject_registry$Subject_Status == "Discontinued", na.rm = TRUE),
      round(sum(subject_registry$Subject_Status == "Randomized", na.rm = TRUE) / 
            nrow(subject_registry) * 100, 1)
    )
  )
  
  # Save report
  report_list <- list(
    Overall_Summary = overall_summary,
    Site_Enrollment = site_enrollment,
    Status_Summary = status_summary,
    Enrollment_Timeline = enrollment_timeline,
    Subject_Details = subject_registry
  )
  
  writexl::write_xlsx(report_list, "outputs/Enrollment_Report.xlsx")
  
  cat("✓ Enrollment report generated: outputs/Enrollment_Report.xlsx\n\n")
  
  cat("Overall Summary:\n")
  print(overall_summary)
  cat("\n")
  
  return(report_list)
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Subject ID Generation Functions Loaded\n\n")

cat("Example usage:\n\n")

cat("# Initialize registry:\n")
cat("initialize_subject_registry()\n\n")

cat("# Enroll subject:\n")
cat('enroll_subject(\n')
cat('  site_number = "USA-001",\n')
cat('  study_id = "STUDY-001"\n')
cat(')\n\n')

cat("# Randomize subject:\n")
cat('randomize_subject(\n')
cat('  usubjid = "STUDY-001-USA-001-0001",\n')
cat('  treatment_assignment = "Treatment A"\n')
cat(')\n\n')

cat("# View registry:\n")
cat("view_subject_registry()\n\n")

cat("# Generate report:\n")
cat("generate_enrollment_report()\n\n")
