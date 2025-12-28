# ==============================================================================
# BDM Validation Script
# Script: validate_bdm.R
# Purpose: Validate BDM specifications for completeness and consistency
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

cat("\n========================================\n")
cat("BDM Validation\n")
cat("========================================\n\n")

#' Validate BDM Specification
#' @param bdm_file Path to BDM Excel file
#' @return Validation report
validate_bdm_spec <- function(bdm_file) {
  
  cat(glue("Validating: {basename(bdm_file)}\n"))
  
  # Read BDM file
  bdm <- readxl::read_excel(bdm_file, sheet = "Mapping_Specification")
  
  # Initialize validation results
  issues <- list()
  warnings <- list()
  
  # Check 1: Required columns present
  required_cols <- c("Source_Variable", "Target_Domain", "Target_Variable", "Mapping_Logic")
  missing_cols <- setdiff(required_cols, names(bdm))
  
  if (length(missing_cols) > 0) {
    issues <- c(issues, glue("Missing required columns: {paste(missing_cols, collapse=', ')}"))
  }
  
  # Check 2: Required SDTM variables mapped
  required_sdtm_vars <- c("STUDYID", "DOMAIN", "USUBJID")
  domain <- unique(bdm$Target_Domain)[1]
  
  if (domain %in% names(SDTM_DOMAINS)) {
    domain_config <- SDTM_DOMAINS[[tolower(domain)]]
    if (!is.null(domain_config$key_vars)) {
      required_vars <- domain_config$key_vars
      mapped_vars <- bdm$Target_Variable[bdm$Target_Variable != ""]
      missing_required <- setdiff(required_vars, mapped_vars)
      
      if (length(missing_required) > 0) {
        issues <- c(issues, glue("Missing required SDTM variables: {paste(missing_required, collapse=', ')}"))
      }
    }
  }
  
  # Check 3: Unmapped source variables
  unmapped_count <- sum(bdm$Target_Variable == "" | is.na(bdm$Target_Variable))
  unmapped_pct <- round(unmapped_count / nrow(bdm) * 100, 1)
  
  if (unmapped_pct > 20) {
    warnings <- c(warnings, glue("{unmapped_pct}% of source variables are unmapped ({unmapped_count}/{nrow(bdm)})"))
  }
  
  # Check 4: Missing mapping logic
  missing_logic <- sum(bdm$Mapping_Logic == "" | is.na(bdm$Mapping_Logic))
  
  if (missing_logic > 0) {
    warnings <- c(warnings, glue("{missing_logic} mapped variables missing mapping logic"))
  }
  
  # Check 5: Duplicate target variables
  mapped_targets <- bdm$Target_Variable[bdm$Target_Variable != "" & !is.na(bdm$Target_Variable)]
  duplicates <- mapped_targets[duplicated(mapped_targets)]
  
  if (length(duplicates) > 0) {
    issues <- c(issues, glue("Duplicate target variables: {paste(unique(duplicates), collapse=', ')}"))
  }
  
  # Generate report
  report <- list(
    file = basename(bdm_file),
    domain = domain,
    total_variables = nrow(bdm),
    mapped_variables = sum(bdm$Target_Variable != "" & !is.na(bdm$Target_Variable)),
    unmapped_variables = unmapped_count,
    issues = issues,
    warnings = warnings,
    status = if (length(issues) == 0) "PASS" else "FAIL"
  )
  
  # Print summary
  cat(sprintf("  Domain: %s\n", domain))
  cat(sprintf("  Total Variables: %d\n", report$total_variables))
  cat(sprintf("  Mapped: %d (%.1f%%)\n", report$mapped_variables, 
              report$mapped_variables / report$total_variables * 100))
  cat(sprintf("  Unmapped: %d (%.1f%%)\n", report$unmapped_variables, unmapped_pct))
  
  if (length(issues) > 0) {
    cat("\n  ✗ ISSUES:\n")
    for (issue in issues) {
      cat(sprintf("    - %s\n", issue))
    }
  }
  
  if (length(warnings) > 0) {
    cat("\n  ⚠ WARNINGS:\n")
    for (warning in warnings) {
      cat(sprintf("    - %s\n", warning))
    }
  }
  
  if (length(issues) == 0 && length(warnings) == 0) {
    cat("\n  ✓ No issues found\n")
  }
  
  cat("\n")
  
  return(report)
}

# ==============================================================================
# Validate All BDM Files
# ==============================================================================

cat("Validating all BDM specifications...\n\n")

bdm_files <- list.files(PATHS$bdm, pattern = "^BDM_[A-Z]{2}_.*\\.xlsx$", full.names = TRUE)

if (length(bdm_files) == 0) {
  cat("No BDM files found in specs/bdm/\n")
  cat("Run R/bdm/generate_all_bdm.R first to generate BDM specifications.\n\n")
} else {
  
  validation_results <- list()
  
  for (bdm_file in bdm_files) {
    result <- validate_bdm_spec(bdm_file)
    validation_results[[basename(bdm_file)]] <- result
  }
  
  # Summary
  cat("========================================\n")
  cat("Validation Summary\n")
  cat("========================================\n\n")
  
  total_files <- length(validation_results)
  passed <- sum(sapply(validation_results, function(x) x$status == "PASS"))
  failed <- total_files - passed
  
  cat(sprintf("Total BDM Files: %d\n", total_files))
  cat(sprintf("Passed: %d\n", passed))
  cat(sprintf("Failed: %d\n", failed))
  
  if (failed > 0) {
    cat("\nFailed Files:\n")
    for (name in names(validation_results)) {
      if (validation_results[[name]]$status == "FAIL") {
        cat(sprintf("  - %s\n", name))
      }
    }
  }
  
  cat("\n========================================\n\n")
}
