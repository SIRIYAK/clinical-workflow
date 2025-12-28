# ==============================================================================
# Statistical Quality Control Checks
# Script: statistical_qc_checks.R
# Purpose: Perform comprehensive statistical QC checks on datasets
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

library(pointblank)
library(validate)

cat("\n========================================\n")
cat("Statistical Quality Control Checks\n")
cat("========================================\n\n")

# ==============================================================================
# Initialize QC Report
# ==============================================================================

qc_results <- list()
qc_timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

# ==============================================================================
# Check 1: Data Completeness
# ==============================================================================

cat("[Check 1] Data Completeness\n")
cat(strrep("-", 80), "\n")

check_completeness <- function(dataset_path, dataset_name) {
  
  data <- haven::read_sas(dataset_path) %>% tibble::as_tibble()
  
  # Calculate missing data percentage for each variable
  missing_summary <- data %>%
    summarise(across(everything(), ~sum(is.na(.)) / n() * 100)) %>%
    pivot_longer(everything(), names_to = "Variable", values_to = "Missing_Pct") %>%
    arrange(desc(Missing_Pct))
  
  # Flag variables with >50% missing
  high_missing <- missing_summary %>%
    filter(Missing_Pct > 50)
  
  result <- list(
    dataset = dataset_name,
    total_vars = ncol(data),
    total_obs = nrow(data),
    vars_high_missing = nrow(high_missing),
    missing_summary = missing_summary
  )
  
  if (nrow(high_missing) > 0) {
    cat(glue("  ⚠ {dataset_name}: {nrow(high_missing)} variable(s) with >50% missing data\n"))
  } else {
    cat(glue("  ✓ {dataset_name}: No variables with excessive missing data\n"))
  }
  
  return(result)
}

# Check ADSL
adsl_completeness <- check_completeness(
  file.path(PATHS$adam, "adsl.sas7bdat"), 
  "ADSL"
)
qc_results$completeness$adsl <- adsl_completeness

# Check ADAE
if (file.exists(file.path(PATHS$adam, "adae.sas7bdat"))) {
  adae_completeness <- check_completeness(
    file.path(PATHS$adam, "adae.sas7bdat"), 
    "ADAE"
  )
  qc_results$completeness$adae <- adae_completeness
}

cat("\n")

# ==============================================================================
# Check 2: Outlier Detection
# ==============================================================================

cat("[Check 2] Outlier Detection\n")
cat(strrep("-", 80), "\n")

detect_outliers <- function(dataset_path, dataset_name, numeric_vars) {
  
  data <- haven::read_sas(dataset_path) %>% tibble::as_tibble()
  
  outlier_summary <- tibble()
  
  for (var in numeric_vars) {
    if (var %in% names(data) && is.numeric(data[[var]])) {
      
      values <- data[[var]][!is.na(data[[var]])]
      
      if (length(values) > 0) {
        # Calculate IQR-based outliers
        Q1 <- quantile(values, 0.25)
        Q3 <- quantile(values, 0.75)
        IQR <- Q3 - Q1
        
        lower_bound <- Q1 - 3 * IQR
        upper_bound <- Q3 + 3 * IQR
        
        outliers <- sum(values < lower_bound | values > upper_bound)
        outlier_pct <- outliers / length(values) * 100
        
        outlier_summary <- bind_rows(outlier_summary, tibble(
          Variable = var,
          N = length(values),
          Outliers = outliers,
          Outlier_Pct = outlier_pct,
          Lower_Bound = lower_bound,
          Upper_Bound = upper_bound
        ))
      }
    }
  }
  
  # Flag variables with >5% outliers
  high_outliers <- outlier_summary %>%
    filter(Outlier_Pct > 5)
  
  if (nrow(high_outliers) > 0) {
    cat(glue("  ⚠ {dataset_name}: {nrow(high_outliers)} variable(s) with >5% outliers\n"))
  } else {
    cat(glue("  ✓ {dataset_name}: No variables with excessive outliers\n"))
  }
  
  return(outlier_summary)
}

# Check ADLB outliers
if (file.exists(file.path(PATHS$adam, "adlb.sas7bdat"))) {
  adlb_outliers <- detect_outliers(
    file.path(PATHS$adam, "adlb.sas7bdat"),
    "ADLB",
    c("AVAL", "BASE", "CHG", "PCHG")
  )
  qc_results$outliers$adlb <- adlb_outliers
}

# Check ADVS outliers
if (file.exists(file.path(PATHS$adam, "advs.sas7bdat"))) {
  advs_outliers <- detect_outliers(
    file.path(PATHS$adam, "advs.sas7bdat"),
    "ADVS",
    c("AVAL", "BASE", "CHG")
  )
  qc_results$outliers$advs <- advs_outliers
}

cat("\n")

# ==============================================================================
# Check 3: Data Consistency
# ==============================================================================

cat("[Check 3] Data Consistency\n")
cat(strrep("-", 80), "\n")

# Check ADSL consistency
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble()

consistency_checks <- list()

# Check 3.1: Treatment dates consistency
date_check <- adsl %>%
  filter(!is.na(TRTSDT), !is.na(TRTEDT)) %>%
  mutate(Date_Issue = TRTEDT < TRTSDT) %>%
  summarise(
    Total = n(),
    Issues = sum(Date_Issue, na.rm = TRUE)
  )

consistency_checks$treatment_dates <- date_check

if (date_check$Issues > 0) {
  cat(glue("  ⚠ Treatment dates: {date_check$Issues} subject(s) with end date before start date\n"))
} else {
  cat("  ✓ Treatment dates: All dates are consistent\n")
}

# Check 3.2: Age consistency
age_check <- adsl %>%
  filter(!is.na(AGE), !is.na(AGEGR1)) %>%
  mutate(
    Age_Group_Correct = case_when(
      AGE < 18 & AGEGR1 == "<18" ~ TRUE,
      AGE >= 18 & AGE < 65 & AGEGR1 == "18-64" ~ TRUE,
      AGE >= 65 & AGE < 75 & AGEGR1 == "65-74" ~ TRUE,
      AGE >= 75 & AGEGR1 == ">=75" ~ TRUE,
      TRUE ~ FALSE
    )
  ) %>%
  summarise(
    Total = n(),
    Issues = sum(!Age_Group_Correct, na.rm = TRUE)
  )

consistency_checks$age_groups <- age_check

if (age_check$Issues > 0) {
  cat(glue("  ⚠ Age groups: {age_check$Issues} subject(s) with inconsistent age grouping\n"))
} else {
  cat("  ✓ Age groups: All age groupings are consistent\n")
}

# Check 3.3: Population flags consistency
pop_check <- adsl %>%
  summarise(
    Total = n(),
    SAFFL_Y = sum(SAFFL == "Y", na.rm = TRUE),
    ITTFL_Y = sum(ITTFL == "Y", na.rm = TRUE),
    ITT_not_SAF = sum(ITTFL == "Y" & SAFFL != "Y", na.rm = TRUE)
  )

consistency_checks$population_flags <- pop_check

if (pop_check$ITT_not_SAF > 0) {
  cat(glue("  ⚠ Population flags: {pop_check$ITT_not_SAF} subject(s) in ITT but not in Safety\n"))
} else {
  cat("  ✓ Population flags: Consistent across populations\n")
}

qc_results$consistency <- consistency_checks

cat("\n")

# ==============================================================================
# Check 4: Cross-Dataset Consistency
# ==============================================================================

cat("[Check 4] Cross-Dataset Consistency\n")
cat(strrep("-", 80), "\n")

# Check 4.1: USUBJID consistency between ADSL and ADAE
if (file.exists(file.path(PATHS$adam, "adae.sas7bdat"))) {
  adae <- haven::read_sas(file.path(PATHS$adam, "adae.sas7bdat")) %>%
    tibble::as_tibble()
  
  usubjid_check <- list(
    adsl_subjects = n_distinct(adsl$USUBJID),
    adae_subjects = n_distinct(adae$USUBJID),
    adae_not_in_adsl = sum(!adae$USUBJID %in% adsl$USUBJID)
  )
  
  qc_results$cross_dataset$usubjid <- usubjid_check
  
  if (usubjid_check$adae_not_in_adsl > 0) {
    cat(glue("  ⚠ USUBJID: {usubjid_check$adae_not_in_adsl} subject(s) in ADAE not found in ADSL\n"))
  } else {
    cat("  ✓ USUBJID: All ADAE subjects exist in ADSL\n")
  }
}

cat("\n")

# ==============================================================================
# Check 5: Statistical Reasonableness
# ==============================================================================

cat("[Check 5] Statistical Reasonableness\n")
cat(strrep("-", 80), "\n")

# Check 5.1: Baseline vs. Change consistency in ADLB
if (file.exists(file.path(PATHS$adam, "adlb.sas7bdat"))) {
  adlb <- haven::read_sas(file.path(PATHS$adam, "adlb.sas7bdat")) %>%
    tibble::as_tibble()
  
  chg_check <- adlb %>%
    filter(!is.na(BASE), !is.na(AVAL), !is.na(CHG)) %>%
    mutate(
      Calculated_CHG = AVAL - BASE,
      CHG_Diff = abs(CHG - Calculated_CHG),
      CHG_Issue = CHG_Diff > 0.01  # Allow small rounding differences
    ) %>%
    summarise(
      Total = n(),
      Issues = sum(CHG_Issue, na.rm = TRUE)
    )
  
  qc_results$statistical$chg_calculation <- chg_check
  
  if (chg_check$Issues > 0) {
    cat(glue("  ⚠ Change from baseline: {chg_check$Issues} record(s) with incorrect CHG calculation\n"))
  } else {
    cat("  ✓ Change from baseline: All calculations are correct\n")
  }
}

cat("\n")

# ==============================================================================
# Generate QC Report
# ==============================================================================

cat("[Phase 6] Generating QC Report\n")
cat(strrep("=", 80), "\n\n")

# Save detailed QC results
qc_report_file <- glue("outputs/validation/stats_checks/Statistical_QC_Report_{qc_timestamp}.xlsx")

# Create workbook with multiple sheets
qc_wb <- list()

# Completeness sheet
if (!is.null(qc_results$completeness$adsl)) {
  qc_wb$ADSL_Completeness <- qc_results$completeness$adsl$missing_summary
}

# Outliers sheet
if (!is.null(qc_results$outliers$adlb)) {
  qc_wb$ADLB_Outliers <- qc_results$outliers$adlb
}

# Consistency checks
consistency_summary <- tibble(
  Check = c("Treatment Dates", "Age Groups", "Population Flags"),
  Total_Records = c(
    consistency_checks$treatment_dates$Total,
    consistency_checks$age_groups$Total,
    consistency_checks$population_flags$Total
  ),
  Issues_Found = c(
    consistency_checks$treatment_dates$Issues,
    consistency_checks$age_groups$Issues,
    consistency_checks$population_flags$ITT_not_SAF
  ),
  Status = if_else(Issues_Found == 0, "PASS", "FAIL")
)

qc_wb$Consistency_Checks <- consistency_summary

# Export
writexl::write_xlsx(qc_wb, qc_report_file)

cat(glue("✓ QC report saved: {qc_report_file}\n\n"))

# ==============================================================================
# Summary
# ==============================================================================

cat("========================================\n")
cat("Statistical QC Summary\n")
cat("========================================\n\n")

total_checks <- 5
passed_checks <- sum(
  qc_results$completeness$adsl$vars_high_missing == 0,
  all(qc_results$outliers$adlb$Outlier_Pct <= 5, na.rm = TRUE),
  consistency_checks$treatment_dates$Issues == 0,
  consistency_checks$age_groups$Issues == 0,
  consistency_checks$population_flags$ITT_not_SAF == 0
)

cat(glue("Total Checks: {total_checks}\n"))
cat(glue("Passed: {passed_checks}\n"))
cat(glue("Failed: {total_checks - passed_checks}\n\n"))

if (passed_checks == total_checks) {
  cat("✓ All statistical QC checks passed!\n")
} else {
  cat("⚠ Some QC checks failed. Review the detailed report.\n")
}

cat(glue("\nDetailed report: {qc_report_file}\n"))
cat("========================================\n\n")
