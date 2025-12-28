# ==============================================================================
# Pinnacle 21 Community Validation Script
# Script: run_p21_validation.R
# Purpose: Run Pinnacle 21 Community validation on SDTM and ADaM datasets
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

cat("\n========================================\n")
cat("Pinnacle 21 Community Validation\n")
cat("========================================\n\n")

# ==============================================================================
# Configuration
# ==============================================================================

# Pinnacle 21 Community executable path
# Update this path based on your P21 installation
P21_PATH <- "C:/Program Files/Pinnacle 21 Community/bin/p21c.exe"

# Check if P21 is installed
if (!file.exists(P21_PATH)) {
  cat("WARNING: Pinnacle 21 Community not found at:", P21_PATH, "\n")
  cat("Please install Pinnacle 21 Community from: https://www.pinnacle21.com/\n")
  cat("Or update P21_PATH in this script to point to your installation.\n\n")
  cat("Validation will be skipped.\n\n")
  quit(save = "no")
}

cat(glue("Pinnacle 21 found at: {P21_PATH}\n\n"))

# ==============================================================================
# Prepare Validation Configuration
# ==============================================================================

cat("Preparing validation configuration...\n")

# Create P21 configuration file
p21_config <- list(
  study_id = STUDY_CONFIG$study_id,
  sdtm_version = STUDY_CONFIG$sdtm_version,
  adam_version = STUDY_CONFIG$adam_version,
  ct_version = STUDY_CONFIG$cdisc_ct_version
)

# ==============================================================================
# Validate SDTM Datasets
# ==============================================================================

cat("\n[Phase 1] Validating SDTM Datasets\n")
cat(strrep("=", 80), "\n\n")

sdtm_xpt_files <- list.files(PATHS$sdtm, pattern = "\\.xpt$", full.names = TRUE)

if (length(sdtm_xpt_files) == 0) {
  cat("No SDTM XPT files found. Please generate SDTM datasets first.\n")
} else {
  cat(glue("Found {length(sdtm_xpt_files)} SDTM datasets\n\n"))
  
  # Create P21 command for SDTM validation
  sdtm_output_dir <- "outputs/validation/p21_reports/sdtm"
  dir.create(sdtm_output_dir, recursive = TRUE, showWarnings = FALSE)
  
  # P21 Community command line syntax
  p21_cmd <- sprintf(
    '"%s" validate --type=sdtm --version=%s --ct-version=%s --input="%s" --output="%s" --format=xlsx',
    P21_PATH,
    STUDY_CONFIG$sdtm_version,
    STUDY_CONFIG$cdisc_ct_version,
    normalizePath(PATHS$sdtm),
    normalizePath(sdtm_output_dir)
  )
  
  cat("Running Pinnacle 21 SDTM validation...\n")
  cat("Command:", p21_cmd, "\n\n")
  
  # Run P21 validation
  tryCatch({
    system(p21_cmd, wait = TRUE)
    cat("✓ SDTM validation complete\n")
    cat(glue("  Report saved to: {sdtm_output_dir}\n\n"))
  }, error = function(e) {
    cat(glue("✗ Error running P21 validation: {e$message}\n\n"))
  })
}

# ==============================================================================
# Validate ADaM Datasets
# ==============================================================================

cat("\n[Phase 2] Validating ADaM Datasets\n")
cat(strrep("=", 80), "\n\n")

adam_xpt_files <- list.files(PATHS$adam, pattern = "\\.xpt$", full.names = TRUE)

if (length(adam_xpt_files) == 0) {
  cat("No ADaM XPT files found. Please generate ADaM datasets first.\n")
} else {
  cat(glue("Found {length(adam_xpt_files)} ADaM datasets\n\n"))
  
  # Create P21 command for ADaM validation
  adam_output_dir <- "outputs/validation/p21_reports/adam"
  dir.create(adam_output_dir, recursive = TRUE, showWarnings = FALSE)
  
  p21_cmd <- sprintf(
    '"%s" validate --type=adam --version=%s --ct-version=%s --input="%s" --output="%s" --format=xlsx',
    P21_PATH,
    STUDY_CONFIG$adam_version,
    STUDY_CONFIG$cdisc_ct_version,
    normalizePath(PATHS$adam),
    normalizePath(adam_output_dir)
  )
  
  cat("Running Pinnacle 21 ADaM validation...\n")
  cat("Command:", p21_cmd, "\n\n")
  
  # Run P21 validation
  tryCatch({
    system(p21_cmd, wait = TRUE)
    cat("✓ ADaM validation complete\n")
    cat(glue("  Report saved to: {adam_output_dir}\n\n"))
  }, error = function(e) {
    cat(glue("✗ Error running P21 validation: {e$message}\n\n"))
  })
}

# ==============================================================================
# Parse P21 Validation Results
# ==============================================================================

cat("\n[Phase 3] Parsing Validation Results\n")
cat(strrep("=", 80), "\n\n")

parse_p21_results <- function(report_dir) {
  
  # Look for P21 Excel reports
  report_files <- list.files(report_dir, pattern = "\\.xlsx$", full.names = TRUE)
  
  if (length(report_files) == 0) {
    cat("No P21 reports found in:", report_dir, "\n")
    return(NULL)
  }
  
  cat(glue("Found {length(report_files)} P21 report(s)\n"))
  
  # Read the first report (P21 typically generates one main report)
  report_file <- report_files[1]
  
  tryCatch({
    # Read issues sheet
    issues <- readxl::read_excel(report_file, sheet = "Issues")
    
    # Summarize by severity
    summary <- issues %>%
      count(Severity) %>%
      arrange(desc(n))
    
    return(list(
      report_file = report_file,
      issues = issues,
      summary = summary
    ))
  }, error = function(e) {
    cat(glue("Error reading P21 report: {e$message}\n"))
    return(NULL)
  })
}

# Parse SDTM results
cat("\nSDTM Validation Results:\n")
sdtm_results <- parse_p21_results(sdtm_output_dir)

if (!is.null(sdtm_results)) {
  print(sdtm_results$summary)
  cat("\n")
}

# Parse ADaM results
cat("\nADaM Validation Results:\n")
adam_results <- parse_p21_results(adam_output_dir)

if (!is.null(adam_results)) {
  print(adam_results$summary)
  cat("\n")
}

# ==============================================================================
# Generate Summary Report
# ==============================================================================

cat("\n[Phase 4] Generating Summary Report\n")
cat(strrep("=", 80), "\n\n")

summary_report <- glue("
# Pinnacle 21 Validation Summary Report

**Study**: {STUDY_CONFIG$study_id}
**Protocol**: {STUDY_CONFIG$protocol}
**Validation Date**: {Sys.Date()}

## SDTM Validation

**Datasets Validated**: {length(sdtm_xpt_files)}
**Report Location**: {sdtm_output_dir}

### Issue Summary
{if (!is.null(sdtm_results)) {
  paste(capture.output(print(sdtm_results$summary)), collapse = '\n')
} else {
  'No results available'
}}

## ADaM Validation

**Datasets Validated**: {length(adam_xpt_files)}
**Report Location**: {adam_output_dir}

### Issue Summary
{if (!is.null(adam_results)) {
  paste(capture.output(print(adam_results$summary)), collapse = '\n')
} else {
  'No results available'
}}

## Next Steps

1. Review detailed P21 reports in Excel format
2. Address all Error-level issues
3. Review and resolve Warning-level issues
4. Document any accepted deviations

---
*Generated by SDTM/ADaM Automation Framework*
")

# Save summary report
summary_file <- "outputs/validation/p21_reports/P21_Validation_Summary.md"
writeLines(summary_report, summary_file)

cat("✓ Summary report saved to:", summary_file, "\n\n")

cat("========================================\n")
cat("✓ Pinnacle 21 validation complete!\n")
cat("========================================\n\n")

cat("Review validation reports:\n")
cat(glue("  SDTM: {sdtm_output_dir}\n"))
cat(glue("  ADaM: {adam_output_dir}\n"))
cat(glue("  Summary: {summary_file}\n\n"))
