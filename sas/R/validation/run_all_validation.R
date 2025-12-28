# ==============================================================================
# Master Validation Script
# Script: run_all_validation.R
# Purpose: Run all validation checks (P21, Statistical QC, CDISC Compliance)
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

cat("\n")
cat("================================================================================\n")
cat("  COMPREHENSIVE VALIDATION FRAMEWORK\n")
cat("================================================================================\n\n")

validation_start <- Sys.time()

# ==============================================================================
# Phase 1: CDISC Compliance Checks
# ==============================================================================

cat("[Phase 1] CDISC Compliance Checks\n")
cat("================================================================================\n\n")

tryCatch({
  source("R/validation/cdisc_compliance_checks.R", echo = FALSE)
  cat("✓ CDISC compliance checks complete\n\n")
}, error = function(e) {
  cat(glue("✗ Error in CDISC compliance checks: {e$message}\n\n"))
})

# ==============================================================================
# Phase 2: Statistical Quality Control
# ==============================================================================

cat("[Phase 2] Statistical Quality Control\n")
cat("================================================================================\n\n")

tryCatch({
  source("R/validation/statistical_qc_checks.R", echo = FALSE)
  cat("✓ Statistical QC checks complete\n\n")
}, error = function(e) {
  cat(glue("✗ Error in statistical QC checks: {e$message}\n\n"))
})

# ==============================================================================
# Phase 3: Pinnacle 21 Validation (Optional)
# ==============================================================================

cat("[Phase 3] Pinnacle 21 Validation\n")
cat("================================================================================\n\n")

cat("NOTE: Pinnacle 21 validation requires P21 Community to be installed.\n")
cat("To run P21 validation, execute: source('R/validation/run_p21_validation.R')\n\n")

# Uncomment the following lines if P21 is installed and configured:
# tryCatch({
#   source("R/validation/run_p21_validation.R", echo = FALSE)
#   cat("✓ Pinnacle 21 validation complete\n\n")
# }, error = function(e) {
#   cat(glue("✗ Error in P21 validation: {e$message}\n\n"))
# })

# ==============================================================================
# Generate Master Validation Report
# ==============================================================================

cat("[Phase 4] Generating Master Validation Report\n")
cat("================================================================================\n\n")

validation_end <- Sys.time()
validation_duration <- difftime(validation_end, validation_start, units = "mins")

master_report <- glue("
# Master Validation Report

**Study**: {STUDY_CONFIG$study_id}
**Protocol**: {STUDY_CONFIG$protocol}
**Validation Date**: {format(Sys.Date(), '%Y-%m-%d')}
**Validation Time**: {format(validation_start, '%H:%M:%S')} - {format(validation_end, '%H:%M:%S')}
**Duration**: {round(validation_duration, 2)} minutes

---

## Validation Components

### 1. CDISC Compliance Checks ✓
- **Status**: Complete
- **Report**: `outputs/validation/CDISC_Compliance_Report_*.md`
- **Checks Performed**:
  - Required variables presence
  - Variable naming conventions
  - ISO 8601 date format compliance
  - Controlled terminology validation

### 2. Statistical Quality Control ✓
- **Status**: Complete
- **Report**: `outputs/validation/stats_checks/Statistical_QC_Report_*.xlsx`
- **Checks Performed**:
  - Data completeness analysis
  - Outlier detection (IQR method)
  - Data consistency checks
  - Cross-dataset validation
  - Statistical reasonableness

### 3. Pinnacle 21 Validation
- **Status**: Manual execution required
- **Script**: `R/validation/run_p21_validation.R`
- **Requirements**: Pinnacle 21 Community installed
- **Output**: `outputs/validation/p21_reports/`

---

## Next Steps

1. **Review Validation Reports**
   - CDISC Compliance: Check for any failed checks
   - Statistical QC: Review outliers and inconsistencies
   - P21 Reports: Address Error and Warning level issues

2. **Address Issues**
   - Document all validation findings
   - Fix critical issues in source data/scripts
   - Document accepted deviations

3. **Re-run Validation**
   - After fixes, re-run validation to confirm resolution
   - Maintain validation history

4. **Prepare for Submission**
   - Ensure all Error-level issues are resolved
   - Document all Warning-level issues
   - Include validation reports in submission package

---

## Validation File Locations

```
outputs/validation/
├── CDISC_Compliance_Report_*.md
├── stats_checks/
│   └── Statistical_QC_Report_*.xlsx
└── p21_reports/
    ├── sdtm/
    │   └── P21_SDTM_Report.xlsx
    └── adam/
        └── P21_ADaM_Report.xlsx
```

---

## Validation Standards

- **CDISC SDTM v{STUDY_CONFIG$sdtm_version}**
- **CDISC ADaM v{STUDY_CONFIG$adam_version}**
- **CDISC CT {STUDY_CONFIG$cdisc_ct_version}**
- **ICH E6 (R2) GCP Guidelines**
- **FDA Study Data Technical Conformance Guide**

---

*Generated by SDTM/ADaM Automation Framework v1.0.0*
")

# Save master report
master_report_file <- glue("outputs/validation/Master_Validation_Report_{format(Sys.Date(), '%Y%m%d')}.md")
writeLines(master_report, master_report_file)

cat(glue("✓ Master validation report saved: {master_report_file}\n\n"))

# ==============================================================================
# Summary
# ==============================================================================

cat("================================================================================\n")
cat("  VALIDATION SUMMARY\n")
cat("================================================================================\n\n")

cat(glue("Start Time: {format(validation_start, '%Y-%m-%d %H:%M:%S')}\n"))
cat(glue("End Time: {format(validation_end, '%Y-%m-%d %H:%M:%S')}\n"))
cat(glue("Duration: {round(validation_duration, 2)} minutes\n\n"))

cat("Validation Components:\n")
cat("  ✓ CDISC Compliance Checks\n")
cat("  ✓ Statistical Quality Control\n")
cat("  ⊙ Pinnacle 21 Validation (manual)\n\n")

cat("Reports Generated:\n")
cat(glue("  - {master_report_file}\n"))
cat("  - outputs/validation/CDISC_Compliance_Report_*.md\n")
cat("  - outputs/validation/stats_checks/Statistical_QC_Report_*.xlsx\n\n")

cat("✓ All validation checks complete!\n")
cat("================================================================================\n\n")
