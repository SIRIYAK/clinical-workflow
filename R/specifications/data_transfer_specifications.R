# ==============================================================================
# Data Transfer Specifications (DTS)
# Script: data_transfer_specifications.R
# Purpose: Generate EDC to SDTM mapping and traceability matrix
# ==============================================================================

source("R/setup/00_install_packages.R")

library(dplyr)
library(glue)
library(writexl)

cat("\n========================================\n")
cat("Data Transfer Specifications\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Generate EDC to SDTM Mapping
# ==============================================================================

generate_edc_to_sdtm_mapping <- function(sdtm_domain) {
  
  # Example mapping template for DM domain
  if (sdtm_domain == "DM") {
    mapping <- tibble(
      SDTM_Domain = "DM",
      SDTM_Variable = c("STUDYID", "USUBJID", "SUBJID", "SITEID", "AGE", "AGEU", 
                       "SEX", "RACE", "ETHNIC", "ARMCD", "ARM", "RFSTDTC", "RFENDTC"),
      EDC_Form = c("Demographics", "Demographics", "Demographics", "Demographics",
                  "Demographics", "Demographics", "Demographics", "Demographics",
                  "Demographics", "Randomization", "Randomization", "Enrollment", "Completion"),
      EDC_Field = c("Study_ID", "Subject_ID", "Subject_Number", "Site_Number",
                   "Age", "Age_Unit", "Sex", "Race", "Ethnicity", "Treatment_Code",
                   "Treatment_Name", "Enrollment_Date", "Completion_Date"),
      Derivation_Logic = c(
        "Direct mapping",
        "Concatenate Study_ID + Site_Number + Subject_Number",
        "Direct mapping",
        "Direct mapping",
        "Direct mapping",
        "Default: YEARS",
        "Map M/F to M/F",
        "Map to CDISC CT",
        "Map to CDISC CT",
        "Direct mapping",
        "Direct mapping",
        "Convert to ISO 8601",
        "Convert to ISO 8601"
      ),
      Data_Type = c("Text", "Text", "Text", "Text", "Numeric", "Text",
                   "Text", "Text", "Text", "Text", "Text", "Date", "Date"),
      Required = c("Yes", "Yes", "Yes", "Yes", "No", "No",
                  "No", "No", "No", "Yes", "Yes", "Yes", "No"),
      Comments = rep("", 13)
    )
  } else {
    # Template for other domains
    mapping <- tibble(
      SDTM_Domain = character(),
      SDTM_Variable = character(),
      EDC_Form = character(),
      EDC_Field = character(),
      Derivation_Logic = character(),
      Data_Type = character(),
      Required = character(),
      Comments = character()
    )
  }
  
  return(mapping)
}

# ==============================================================================
# 2. Generate Complete DTS Document
# ==============================================================================

generate_complete_dts <- function(sdtm_domains = c("DM", "AE", "VS", "LB")) {
  
  cat("Generating Data Transfer Specifications...\n\n")
  
  all_mappings <- list()
  
  for (domain in sdtm_domains) {
    cat(glue("  Generating mapping for {domain}...\n"))
    all_mappings[[domain]] <- generate_edc_to_sdtm_mapping(domain)
  }
  
  # Combine all mappings
  combined_mapping <- bind_rows(all_mappings)
  
  # Generate traceability matrix
  traceability_matrix <- combined_mapping %>%
    select(SDTM_Domain, SDTM_Variable, EDC_Form, EDC_Field, Derivation_Logic) %>%
    mutate(
      Traceability_ID = sprintf("TRACE-%04d", row_number()),
      Verified_By = "",
      Verification_Date = as.Date(NA)
    )
  
  # Save DTS
  dts_list <- list(
    EDC_to_SDTM_Mapping = combined_mapping,
    Traceability_Matrix = traceability_matrix,
    Summary = combined_mapping %>%
      group_by(SDTM_Domain) %>%
      summarise(
        Total_Variables = n(),
        Required_Variables = sum(Required == "Yes", na.rm = TRUE),
        .groups = "drop"
      )
  )
  
  writexl::write_xlsx(dts_list, "docs/Data_Transfer_Specifications.xlsx")
  
  cat("\n✓ Data Transfer Specifications generated: docs/Data_Transfer_Specifications.xlsx\n\n")
  
  return(dts_list)
}

# ==============================================================================
# 3. Validate EDC Data Against Mapping
# ==============================================================================

validate_edc_data <- function(edc_data, sdtm_domain) {
  
  cat(glue("Validating EDC data for {sdtm_domain}...\n\n"))
  
  # Get mapping
  mapping <- generate_edc_to_sdtm_mapping(sdtm_domain)
  
  # Check required fields
  required_fields <- mapping %>%
    filter(Required == "Yes") %>%
    pull(EDC_Field)
  
  missing_fields <- setdiff(required_fields, names(edc_data))
  
  validation_results <- list(
    domain = sdtm_domain,
    total_fields = nrow(mapping),
    required_fields = length(required_fields),
    missing_fields = missing_fields,
    validation_status = if_else(length(missing_fields) == 0, "PASS", "FAIL")
  )
  
  if (length(missing_fields) > 0) {
    cat("✗ VALIDATION FAILED\n")
    cat(glue("  Missing required fields: {paste(missing_fields, collapse = ', ')}\n\n"))
  } else {
    cat("✓ VALIDATION PASSED\n")
    cat("  All required fields present\n\n")
  }
  
  return(validation_results)
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Data Transfer Specifications Functions Loaded\n\n")

cat("Example usage:\n\n")

cat("# Generate complete DTS:\n")
cat('generate_complete_dts(sdtm_domains = c("DM", "AE", "VS", "LB"))\n\n')

cat("# Validate EDC data:\n")
cat('validate_edc_data(edc_data = my_edc_data, sdtm_domain = "DM")\n\n')
