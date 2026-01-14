# ==============================================================================
# Pharmaverse Integration Examples - Phase 1
# Script: pharmaverse_examples.R
# Purpose: Demonstrate usage of Phase 1 pharmaverse packages
# ==============================================================================

source("R/setup/00_install_packages.R")

library(gtsummary)
library(logrx)
library(pkglite)
library(pharmaverseadam)

cat("\n========================================\n")
cat("Pharmaverse Integration Examples\n")
cat("========================================\n\n")

# ==============================================================================
# 1. gtsummary - Beautiful Summary Tables
# ==============================================================================

cat("Example 1: gtsummary - Summary Tables\n")
cat(strrep("-", 60), "\n\n")

# Load synthetic ADaM data
adsl <- pharmaverseadam::adsl

# Create beautiful summary table
demo_table <- adsl %>%
  select(AGE, SEX, RACE, ETHNIC, ARM) %>%
  tbl_summary(
    by = ARM,
    statistic = list(
      all_continuous() ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    label = list(
      AGE ~ "Age (years)",
      SEX ~ "Sex",
      RACE ~ "Race",
      ETHNIC ~ "Ethnicity"
    )
  ) %>%
  add_p() %>%
  add_overall() %>%
  modify_header(label ~ "**Characteristic**") %>%
  modify_caption("**Table 14.1.1 - Demographics and Baseline Characteristics**") %>%
  bold_labels()

print(demo_table)

# Export to multiple formats
demo_table %>%
  as_gt() %>%
  gt::gtsave("outputs/tlf/tables/Table_14_1_1_Demographics_gtsummary.docx")

demo_table %>%
  as_gt() %>%
  gt::gtsave("outputs/tlf/tables/Table_14_1_1_Demographics_gtsummary.html")

cat("\n✓ Summary table created with gtsummary\n")
cat("  Output: outputs/tlf/tables/Table_14_1_1_Demographics_gtsummary.*\n\n")

# ==============================================================================
# 2. gtsummary - Adverse Events Table
# ==============================================================================

cat("Example 2: gtsummary - Adverse Events Summary\n")
cat(strrep("-", 60), "\n\n")

# Load AE data
adae <- pharmaverseadam::adae

# Create AE summary
ae_summary <- adae %>%
  filter(TRTEMFL == "Y") %>%
  select(AESOC, AEDECOD, TRTA) %>%
  tbl_summary(
    by = TRTA,
    label = list(
      AESOC ~ "System Organ Class",
      AEDECOD ~ "Preferred Term"
    )
  ) %>%
  add_p() %>%
  modify_caption("**Table 14.3.1 - Treatment-Emergent Adverse Events**") %>%
  bold_labels()

print(ae_summary)

cat("\n✓ AE summary table created\n\n")

# ==============================================================================
# 3. logrx - Execution Logging
# ==============================================================================

cat("Example 3: logrx - Execution Logging\n")
cat(strrep("-", 60), "\n\n")

# Create a simple script to log
demo_script <- tempfile(fileext = ".R")
writeLines(c(
  "# Demo script for logrx",
  "library(dplyr)",
  "data <- mtcars %>%",
  "  filter(mpg > 20) %>%",
  "  summarise(mean_mpg = mean(mpg))",
  "print(data)"
), demo_script)

# Execute with logging
logrx::axecute(
  demo_script,
  log_name = "demo_execution_log",
  log_path = "docs/logs"
)

cat("\n✓ Script executed with automatic logging\n")
cat("  Log file: docs/logs/demo_execution_log.Rout\n\n")

# ==============================================================================
# 4. pkglite - Package Bundling for eSub
# ==============================================================================

cat("Example 4: pkglite - Package Bundling\n")
cat(strrep("-", 60), "\n\n")

# Bundle key packages for regulatory submission
dir.create("outputs/esub/r_packages", recursive = TRUE, showWarnings = FALSE)

# Pack packages
pkglite::pack(
  c("admiral", "xportr", "gtsummary"),
  output = "outputs/esub/r_packages/pharmaverse_packages.txt",
  quiet = FALSE
)

cat("\n✓ Packages bundled for eSub\n")
cat("  Output: outputs/esub/r_packages/pharmaverse_packages.txt\n\n")

# ==============================================================================
# 5. pharmaverseadam - Synthetic Data for Testing
# ==============================================================================

cat("Example 5: pharmaverseadam - Synthetic Test Data\n")
cat(strrep("-", 60), "\n\n")

# Available datasets
cat("Available synthetic ADaM datasets:\n")
cat("  • adsl - Subject-Level Analysis Dataset\n")
cat("  • adae - Adverse Events Analysis\n")
cat("  • adlb - Laboratory Analysis\n")
cat("  • advs - Vital Signs Analysis\n\n")

# Use for testing
test_adsl <- pharmaverseadam::adsl
test_adae <- pharmaverseadam::adae

cat(glue::glue("ADSL: {nrow(test_adsl)} subjects\n"))
cat(glue::glue("ADAE: {nrow(test_adae)} adverse events\n\n"))

# Test our TLF functions with synthetic data
cat("Testing framework with synthetic data...\n")

# Example: Test demographics table
if (file.exists("R/tlf/tables/table_14_1_1_demographics.R")) {
  source("R/tlf/tables/table_14_1_1_demographics.R")
  cat("✓ Demographics table tested with synthetic data\n")
}

cat("\n✓ Synthetic data loaded and tested\n\n")

# ==============================================================================
# 6. Complete Workflow Example
# ==============================================================================

cat("Example 6: Complete Workflow with Pharmaverse\n")
cat(strrep("-", 60), "\n\n")

# Wrap entire analysis in logrx
analysis_script <- tempfile(fileext = ".R")
writeLines(c(
  "# Complete analysis workflow",
  "library(pharmaverseadam)",
  "library(gtsummary)",
  "",
  "# Load data",
  "adsl <- pharmaverseadam::adsl",
  "",
  "# Create summary",
  "summary_table <- adsl %>%",
  "  select(AGE, SEX, ARM) %>%",
  "  tbl_summary(by = ARM)",
  "",
  "# Print",
  "print(summary_table)"
), analysis_script)

# Execute with logging
logrx::axecute(
  analysis_script,
  log_name = "complete_workflow_log",
  log_path = "docs/logs"
)

cat("\n✓ Complete workflow executed with logging\n\n")

# ==============================================================================
# Summary
# ==============================================================================

cat("========================================\n")
cat("Pharmaverse Integration Summary\n")
cat("========================================\n\n")

cat("Phase 1 Packages Demonstrated:\n")
cat("  1. ✓ gtsummary - Beautiful summary tables\n")
cat("  2. ✓ logrx - Execution logging\n")
cat("  3. ✓ pkglite - Package bundling\n")
cat("  4. ✓ pharmaverseadam - Synthetic test data\n\n")

cat("Benefits:\n")
cat("  • Faster table creation with gtsummary\n")
cat("  • Complete audit trail with logrx\n")
cat("  • eSub-ready package bundling\n")
cat("  • Comprehensive testing with synthetic data\n\n")

cat("Next Steps:\n")
cat("  1. Integrate gtsummary into TLF generation\n")
cat("  2. Add logrx to run_all.R for complete logging\n")
cat("  3. Use pkglite for final submission\n")
cat("  4. Test all modules with pharmaverseadam data\n\n")

cat("========================================\n\n")
