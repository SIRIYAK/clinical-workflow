# ==============================================================================
# CDISC Compliance Checks
# Script: cdisc_compliance_checks.R
# Purpose: Perform CDISC-specific compliance checks
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

cat("\n========================================\n")
cat("CDISC Compliance Checks\n")
cat("========================================\n\n")

compliance_results <- list()

# ==============================================================================
# Check 1: Required Variables Present
# ==============================================================================

cat("[Check 1] Required Variables\n")
cat(strrep("-", 80), "\n")

check_required_vars <- function(dataset_path, domain, required_vars) {
  
  data <- haven::read_sas(dataset_path) %>% tibble::as_tibble()
  
  missing_vars <- setdiff(required_vars, names(data))
  
  result <- list(
    domain = domain,
    required_vars = required_vars,
    present_vars = intersect(required_vars, names(data)),
    missing_vars = missing_vars,
    status = if_else(length(missing_vars) == 0, "PASS", "FAIL")
  )
  
  if (length(missing_vars) > 0) {
    cat(glue("  ✗ {domain}: Missing required variables: {paste(missing_vars, collapse=', ')}\n"))
  } else {
    cat(glue("  ✓ {domain}: All required variables present\n"))
  }
  
  return(result)
}

# Check SDTM domains
sdtm_checks <- list()

# DM required variables
if (file.exists(file.path(PATHS$sdtm, "dm.sas7bdat"))) {
  sdtm_checks$dm <- check_required_vars(
    file.path(PATHS$sdtm, "dm.sas7bdat"),
    "DM",
    c("STUDYID", "DOMAIN", "USUBJID", "SUBJID", "RFSTDTC", "RFENDTC", "SITEID", "AGE", "SEX", "RACE", "ETHNIC", "ARMCD", "ARM", "ACTARMCD", "ACTARM", "COUNTRY", "DMDTC", "DMDY")
  )
}

# AE required variables
if (file.exists(file.path(PATHS$sdtm, "ae.sas7bdat"))) {
  sdtm_checks$ae <- check_required_vars(
    file.path(PATHS$sdtm, "ae.sas7bdat"),
    "AE",
    c("STUDYID", "DOMAIN", "USUBJID", "AESEQ", "AETERM", "AEDECOD", "AEBODSYS", "AESTDTC", "AEENDTC", "AESEV", "AESER", "AEREL")
  )
}

compliance_results$required_vars$sdtm <- sdtm_checks

# Check ADaM datasets
adam_checks <- list()

# ADSL required variables
if (file.exists(file.path(PATHS$adam, "adsl.sas7bdat"))) {
  adam_checks$adsl <- check_required_vars(
    file.path(PATHS$adam, "adsl.sas7bdat"),
    "ADSL",
    c("STUDYID", "USUBJID", "SUBJID", "SITEID", "AGE", "SEX", "RACE", "TRT01P", "TRT01A", "TRTSDT", "TRTEDT", "SAFFL", "ITTFL")
  )
}

compliance_results$required_vars$adam <- adam_checks

cat("\n")

# ==============================================================================
# Check 2: Variable Naming Conventions
# ==============================================================================

cat("[Check 2] Variable Naming Conventions\n")
cat(strrep("-", 80), "\n")

check_naming_conventions <- function(dataset_path, domain) {
  
  data <- haven::read_sas(dataset_path) %>% tibble::as_tibble()
  
  # Check for lowercase variable names (CDISC requires uppercase)
  lowercase_vars <- names(data)[names(data) != toupper(names(data))]
  
  # Check for special characters (only alphanumeric and underscore allowed)
  special_char_vars <- names(data)[!grepl("^[A-Z0-9_]+$", names(data))]
  
  # Check variable name length (max 8 characters for SDTM)
  if (grepl("^(DM|AE|CM|VS|LB|EG|EX|DS|MH|SU)$", domain)) {
    long_vars <- names(data)[nchar(names(data)) > 8]
  } else {
    long_vars <- character(0)
  }
  
  issues <- c(lowercase_vars, special_char_vars, long_vars)
  
  if (length(issues) > 0) {
    cat(glue("  ⚠ {domain}: {length(issues)} naming convention issue(s)\n"))
  } else {
    cat(glue("  ✓ {domain}: All variable names comply with CDISC conventions\n"))
  }
  
  return(list(
    domain = domain,
    lowercase_vars = lowercase_vars,
    special_char_vars = special_char_vars,
    long_vars = long_vars,
    status = if_else(length(issues) == 0, "PASS", "FAIL")
  ))
}

# Check SDTM domains
if (file.exists(file.path(PATHS$sdtm, "dm.sas7bdat"))) {
  compliance_results$naming$dm <- check_naming_conventions(
    file.path(PATHS$sdtm, "dm.sas7bdat"), "DM"
  )
}

# Check ADaM datasets
if (file.exists(file.path(PATHS$adam, "adsl.sas7bdat"))) {
  compliance_results$naming$adsl <- check_naming_conventions(
    file.path(PATHS$adam, "adsl.sas7bdat"), "ADSL"
  )
}

cat("\n")

# ==============================================================================
# Check 3: Date Format Compliance
# ==============================================================================

cat("[Check 3] ISO 8601 Date Format\n")
cat(strrep("-", 80), "\n")

check_iso_dates <- function(dataset_path, domain, date_vars) {
  
  data <- haven::read_sas(dataset_path) %>% tibble::as_tibble()
  
  iso_pattern <- "^\\d{4}(-\\d{2}(-\\d{2}(T\\d{2}:\\d{2}(:\\d{2})?)?)?)?$"
  
  date_issues <- list()
  
  for (var in date_vars) {
    if (var %in% names(data)) {
      values <- data[[var]][!is.na(data[[var]])]
      
      if (length(values) > 0 && is.character(values)) {
        non_iso <- sum(!grepl(iso_pattern, values))
        
        if (non_iso > 0) {
          date_issues[[var]] <- non_iso
        }
      }
    }
  }
  
  if (length(date_issues) > 0) {
    cat(glue("  ⚠ {domain}: {length(date_issues)} date variable(s) with non-ISO 8601 format\n"))
  } else {
    cat(glue("  ✓ {domain}: All dates in ISO 8601 format\n"))
  }
  
  return(list(
    domain = domain,
    date_issues = date_issues,
    status = if_else(length(date_issues) == 0, "PASS", "FAIL")
  ))
}

# Check DM dates
if (file.exists(file.path(PATHS$sdtm, "dm.sas7bdat"))) {
  compliance_results$iso_dates$dm <- check_iso_dates(
    file.path(PATHS$sdtm, "dm.sas7bdat"),
    "DM",
    c("RFSTDTC", "RFENDTC", "RFXSTDTC", "RFXENDTC", "DMDTC", "BRTHDTC")
  )
}

cat("\n")

# ==============================================================================
# Check 4: Controlled Terminology
# ==============================================================================

cat("[Check 4] Controlled Terminology\n")
cat(strrep("-", 80), "\n")

check_controlled_terminology <- function(dataset_path, domain, ct_vars) {
  
  data <- haven::read_sas(dataset_path) %>% tibble::as_tibble()
  
  ct_issues <- list()
  
  for (var_info in ct_vars) {
    var <- var_info$var
    permitted_values <- var_info$values
    
    if (var %in% names(data)) {
      values <- unique(data[[var]][!is.na(data[[var]])])
      
      invalid_values <- setdiff(values, permitted_values)
      
      if (length(invalid_values) > 0) {
        ct_issues[[var]] <- invalid_values
      }
    }
  }
  
  if (length(ct_issues) > 0) {
    cat(glue("  ⚠ {domain}: {length(ct_issues)} variable(s) with invalid CT values\n"))
  } else {
    cat(glue("  ✓ {domain}: All CT values are valid\n"))
  }
  
  return(list(
    domain = domain,
    ct_issues = ct_issues,
    status = if_else(length(ct_issues) == 0, "PASS", "FAIL")
  ))
}

# Check DM controlled terminology
if (file.exists(file.path(PATHS$sdtm, "dm.sas7bdat"))) {
  dm_ct <- list(
    list(var = "SEX", values = c("M", "F", "U")),
    list(var = "RACE", values = c("WHITE", "BLACK OR AFRICAN AMERICAN", "ASIAN", "AMERICAN INDIAN OR ALASKA NATIVE", "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER", "OTHER", "MULTIPLE", "UNKNOWN")),
    list(var = "ETHNIC", values = c("HISPANIC OR LATINO", "NOT HISPANIC OR LATINO", "NOT REPORTED", "UNKNOWN"))
  )
  
  compliance_results$controlled_terminology$dm <- check_controlled_terminology(
    file.path(PATHS$sdtm, "dm.sas7bdat"),
    "DM",
    dm_ct
  )
}

cat("\n")

# ==============================================================================
# Generate Compliance Report
# ==============================================================================

cat("[Phase 5] Generating Compliance Report\n")
cat(strrep("=", 80), "\n\n")

# Summarize results
total_checks <- 0
passed_checks <- 0

for (check_type in names(compliance_results)) {
  for (domain in names(compliance_results[[check_type]])) {
    total_checks <- total_checks + 1
    if (compliance_results[[check_type]][[domain]]$status == "PASS") {
      passed_checks <- passed_checks + 1
    }
  }
}

# Create summary
compliance_summary <- glue("
# CDISC Compliance Check Report

**Study**: {STUDY_CONFIG$study_id}
**Check Date**: {Sys.Date()}

## Summary

**Total Checks**: {total_checks}
**Passed**: {passed_checks}
**Failed**: {total_checks - passed_checks}
**Pass Rate**: {round(passed_checks / total_checks * 100, 1)}%

## Check Results

### Required Variables
{paste(sapply(names(compliance_results$required_vars$sdtm), function(d) {
  result <- compliance_results$required_vars$sdtm[[d]]
  glue('- **{result$domain}**: {result$status}')
}), collapse = '\n')}

### Naming Conventions
{paste(sapply(names(compliance_results$naming), function(d) {
  result <- compliance_results$naming[[d]]
  glue('- **{result$domain}**: {result$status}')
}), collapse = '\n')}

### ISO 8601 Dates
{paste(sapply(names(compliance_results$iso_dates), function(d) {
  result <- compliance_results$iso_dates[[d]]
  glue('- **{result$domain}**: {result$status}')
}), collapse = '\n')}

### Controlled Terminology
{paste(sapply(names(compliance_results$controlled_terminology), function(d) {
  result <- compliance_results$controlled_terminology[[d]]
  glue('- **{result$domain}**: {result$status}')
}), collapse = '\n')}

---
*Generated by SDTM/ADaM Automation Framework*
")

# Save report
compliance_report_file <- glue("outputs/validation/CDISC_Compliance_Report_{format(Sys.Date(), '%Y%m%d')}.md")
writeLines(compliance_summary, compliance_report_file)

cat(glue("✓ Compliance report saved: {compliance_report_file}\n\n"))

cat("========================================\n")
cat("CDISC Compliance Check Complete\n")
cat("========================================\n\n")

cat(glue("Pass Rate: {round(passed_checks / total_checks * 100, 1)}%\n"))
cat(glue("Report: {compliance_report_file}\n\n"))
